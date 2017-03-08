FactoryGirl.define do
  factory :geo_node_key, class: 'GeoNodeKey' do
    title
    key do
      SSHKeygen.generate
    end
  end
end
