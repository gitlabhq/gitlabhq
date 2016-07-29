FactoryGirl.define do
  factory :ldap_group_link do
    cn 'group1'
    group_access Gitlab::Access::GUEST
    provider 'ldapmain'
    group
  end
end
