# frozen_string_literal: true

FactoryBot.define do
  factory :go_module_version, class: 'Packages::Go::ModuleVersion' do
    skip_create

    initialize_with do
      p = attributes[:params]
      s = Packages::SemVer.parse(p.semver, prefixed: true)

      raise ArgumentError.new("invalid sematic version: '#{p.semver}''") if !s && p.semver

      new(p.mod, p.type, p.commit, name: p.name, semver: s, ref: p.ref)
    end

    mod { create :go_module }
    type { :commit }
    commit { mod.project.repository.head_commit }
    name { nil }
    semver { nil }
    ref { nil }

    params { OpenStruct.new(mod: mod, type: type, commit: commit, name: name, semver: semver, ref: ref) }

    trait :tagged do
      ref { mod.project.repository.find_tag(name) }
      commit { ref.dereferenced_target }
      name do
        # This provides a sane default value, but in reality the caller should
        # specify `name:`

        # Find 'latest' semver tag (does not actually use semver precedence rules)
        mod.project.repository.tags
          .filter { |t| Packages::SemVer.match?(t.name, prefixed: true) }
          .map    { |t| Packages::SemVer.parse(t.name, prefixed: true) }
          .max    { |a, b| "#{a}" <=> "#{b}" }
          .to_s
      end

      params { OpenStruct.new(mod: mod, type: :ref, commit: commit, semver: name, ref: ref) }
    end

    trait :pseudo do
      transient do
        prefix do
          # This provides a sane default value, but in reality the caller should
          # specify `prefix:`

          # This does not take into account that `commit` may be before the
          # latest tag.

          # Find 'latest' semver tag (does not actually use semver precedence rules)
          v = mod.project.repository.tags
            .filter { |t| Packages::SemVer.match?(t.name, prefixed: true) }
            .map    { |t| Packages::SemVer.parse(t.name, prefixed: true) }
            .max    { |a, b| "#{a}" <=> "#{b}" }

          # Default if no semver tags exist
          next 'v0.0.0' unless v

          # Valid pseudo-versions are:
          #   vX.0.0-yyyymmddhhmmss-sha1337beef0, when no earlier tagged commit exists for X
          #   vX.Y.Z-pre.0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z-pre
          #   vX.Y.(Z+1)-0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z

          v = v.with(patch: v.patch + 1) unless v.prerelease
          "#{v}.0"
        end
      end

      type { :pseudo }
      name { "#{prefix}#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..11]}" }

      params { OpenStruct.new(mod: mod, type: :pseudo, commit: commit, name: name, semver: name) }
    end
  end
end
