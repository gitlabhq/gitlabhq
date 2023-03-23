# frozen_string_literal: true

FactoryBot.define do
  factory :clusters_applications_helm, class: 'Clusters::Applications::Helm' do
    cluster factory: %i(cluster provided_by_gcp)

    transient do
      helm_installed { true }
    end

    before(:create) do |_record, evaluator|
      if evaluator.helm_installed
        stub_method(Gitlab::Kubernetes::Helm::V2::Certificate, :generate_root) do
          OpenStruct.new( # rubocop: disable Style/OpenStructUse
            key_string: File.read(Rails.root.join('spec/fixtures/clusters/sample_key.key')),
            cert_string: File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem'))
          )
        end
      end
    end

    after(:create) do |_record, evaluator|
      if evaluator.helm_installed
        restore_original_methods(Gitlab::Kubernetes::Helm::V2::Certificate)
      end
    end

    trait :not_installable do
      status { -2 }
    end

    trait :errored do
      status { -1 }
      status_reason { 'something went wrong' }
    end

    trait :installable do
      status { 0 }
    end

    trait :scheduled do
      status { 1 }
    end

    trait :installing do
      status { 2 }
    end

    trait :installed do
      status { 3 }
    end

    trait :updating do
      status { 4 }
    end

    trait :updated do
      status { 5 }
    end

    trait :update_errored do
      status { 6 }
      status_reason { 'something went wrong' }
    end

    trait :uninstalling do
      status { 7 }
    end

    trait :uninstall_errored do
      status { 8 }
      status_reason { 'something went wrong' }
    end

    trait :uninstalled do
      status { 10 }
    end

    trait :externally_installed do
      status { 11 }
    end

    trait :timed_out do
      installing
      updated_at { ClusterWaitForAppInstallationWorker::TIMEOUT.ago }
    end

    # Common trait used by the apps below
    trait :no_helm_installed do
      cluster factory: %i(cluster provided_by_gcp)

      transient do
        helm_installed { false }
      end
    end

    factory :clusters_applications_ingress, class: 'Clusters::Applications::Ingress' do
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end
  end
end
