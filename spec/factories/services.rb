FactoryGirl.define do
  factory :service do
    project factory: :empty_project
  end

  factory :kubernetes_service do
    project factory: :empty_project
    active true
    properties({
      namespace: 'somepath',
      api_url: 'https://kubernetes.example.com',
      token: 'a' * 40,
    })
  end
end
