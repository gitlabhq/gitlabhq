# frozen_string_literal: true

FactoryBot.define do
  factory :go_module_version, class: 'Packages::Go::ModuleVersion' do
    skip_create

    initialize_with do
      s = Packages::SemVer.parse(semver, prefixed: true)
      raise ArgumentError, "invalid sematic version: #{semver.inspect}" if !s && semver

      new(mod, type, commit, name: name, semver: s, ref: ref)
    end

    mod { association(:go_module) }
    type { :commit }
    commit { mod.project.repository.head_commit }
    name { nil }
    semver { nil }
    ref { nil }

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
      type { :ref }
      semver { name }
    end
  end
end
