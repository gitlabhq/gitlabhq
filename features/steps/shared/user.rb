module SharedUser
  include Spinach::DSL

  step 'User "John Doe" exists' do
    user_exists("John Doe", { username: "john_doe" })
  end

  step 'User "Mary Jane" exists' do
    user_exists("Mary Jane", { username: "mary_jane" })
  end

  step 'gitlab user "Mike"' do
    create(:user, name: "Mike")
  end

  protected

  def user_exists(name, options = {})
    User.find_by(name: name) || create(:user, { name: name, admin: false }.merge(options))
  end

  step 'I have an ssh key' do
    create(:key, user: @user, title: "An ssh-key", key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+L3TbFegm3k8QjejSwemk4HhlRh+DuN679Pc5ckqE/MPhVtE/+kZQDYCTB284GiT2aIoGzmZ8ee9TkaoejAsBwlA+Wz2Q3vhz65X6sMgalRwpdJx8kSEUYV8ZPV3MZvPo8KdNg993o4jL6G36GDW4BPIyO6FPZhfsawdf6liVD0Xo5kibIK7B9VoE178cdLQtLpS2YolRwf5yy6XR6hbbBGQR+6xrGOdP16eGZDb1CE2bMvvJijjloFqPscGktWOqW+nfh5txwFfBzlfARDTBsS8WZtg3Yoj1kn33kPsWRlgHfNutFRAIynDuDdQzQq8tTtVwm+Yi75RfcPHW8y3P Work")
  end

  step 'I have no ssh keys' do
    Key.delete_all
  end
end
