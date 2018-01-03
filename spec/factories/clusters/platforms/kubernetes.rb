FactoryBot.define do
  factory :cluster_platform_kubernetes, class: Clusters::Platforms::Kubernetes do
    cluster
    namespace nil
    api_url 'https://kubernetes.example.com'
    token 'a' * 40

    trait :configured do
      api_url 'https://kubernetes.example.com'
      token 'a' * 40
      username 'xxxxxx'
      password 'xxxxxx'

      after(:create) do |platform_kubernetes, evaluator|
        pem_file = File.expand_path(Rails.root.join('spec/fixtures/clusters/sample_cert.pem'))
        platform_kubernetes.ca_cert = File.read(pem_file)
      end
    end
  end
end
