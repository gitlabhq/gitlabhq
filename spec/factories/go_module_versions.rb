# frozen_string_literal: true

FactoryBot.define do
  factory :go_module_version, class: 'Packages::Go::ModuleVersion' do
    skip_create

    initialize_with do
      p = attributes[:params]
      s = Packages::SemVer.parse(p.semver, prefixed: true)

      raise ArgumentError, "invalid sematic version: '#{p.semver}'" if !s && p.semver

      new(p.mod, p.type, p.commit, name: p.name, semver: s, ref: p.ref)
    end

    mod { association(:go_module) }
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
          .max_by(&:to_s)
          .to_s
      end

      params { OpenStruct.new(mod: mod, type: :ref, commit: commit, semver: name, ref: ref) }
    end
  end
end
