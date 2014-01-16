module SharedUser
  include Spinach::DSL

  step 'public user "John Van Public"' do
    create(:user, name: 'John Van Public', username: 'john_van_public',
        visibility_level: Gitlab::VisibilityLevel::PUBLIC)
  end

  step 'internal user "John Van Internal"' do
    create(:user, name: 'John Van Internal', username: 'john_van_internal',
        visibility_level: Gitlab::VisibilityLevel::INTERNAL)
  end

  step 'private user "John Van Private"' do
    create(:user, name: 'John Van Private', username: 'john_van_private',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE)
  end
end
