FactoryGirl.define do
  factory :platform_kubernetes, class: Clusters::Platforms::Kubernetes do
    cluster
    namespace nil

    trait :ca_cert do
      after(:create) do |platform_kubernetes, evaluator|
        pem_file = File.expand_path(Rails.root.join('spec/fixtures/clusters/sample_cert.pem'))
        platform_kubernetes.ca_cert = File.read(pem_file)
      end
    end

    trait :configured do
      api_url 'https://kubernetes.example.com'
      ca_cert nil
      token 'a' * 40
      username 'xxxxxx'
      password 'xxxxxx'
    end
  end
end
