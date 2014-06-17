require 'spec_helper'

describe ApplicationHelper do
  describe 'current_controller?' do
    before do
      controller.stub(:controller_name).and_return('foo')
    end

    it "returns true when controller matches argument" do
      current_controller?(:foo).should be_true
    end

    it "returns false when controller does not match argument" do
      current_controller?(:bar).should_not be_true
    end

    it "should take any number of arguments" do
      current_controller?(:baz, :bar).should_not be_true
      current_controller?(:baz, :bar, :foo).should be_true
    end
  end

  describe 'current_action?' do
    before do
      allow(self).to receive(:action_name).and_return('foo')
    end

    it "returns true when action matches argument" do
      current_action?(:foo).should be_true
    end

    it "returns false when action does not match argument" do
      current_action?(:bar).should_not be_true
    end

    it "should take any number of arguments" do
      current_action?(:baz, :bar).should_not be_true
      current_action?(:baz, :bar, :foo).should be_true
    end
  end

  describe "group_icon" do
    avatar_file_path = File.join(Rails.root, 'public', 'gitlab_logo.png')

    it "should return an url for the avatar" do
      group = create(:group)
      group.avatar = File.open(avatar_file_path)
      group.save!
      group_icon(group.path).to_s.should match("/uploads/group/avatar/#{ group.id }/gitlab_logo.png")
    end

    it "should give default avatar_icon when no avatar is present" do
      group = create(:group)
      group.save!
      group_icon(group.path).should match("group_avatar.png")
    end
  end

  describe "avatar_icon" do
    avatar_file_path = File.join(Rails.root, 'public', 'gitlab_logo.png')

    it "should return an url for the avatar" do
      user = create(:user)
      user.avatar = File.open(avatar_file_path)
      user.save!
      avatar_icon(user.email).to_s.should match("/uploads/user/avatar/#{ user.id }/gitlab_logo.png")
    end

    it "should call gravatar_icon when no avatar is present" do
      user = create(:user, email: 'test@example.com')
      user.save!
      avatar_icon(user.email).to_s.should == "http://www.gravatar.com/avatar/55502f40dc8b7c769880b10874abc9d0?s=40&d=identicon"
    end
  end

  describe "gravatar_icon" do
    let(:user_email) { 'user@email.com' }

    it "should return a generic avatar path when Gravatar is disabled" do
      Gitlab.config.gravatar.stub(:enabled).and_return(false)
      gravatar_icon(user_email).should match('no_avatar.png')
    end

    it "should return a generic avatar path when email is blank" do
      gravatar_icon('').should match('no_avatar.png')
    end

    it "should return default gravatar url" do
      Gitlab.config.gitlab.stub(https: false)
      gravatar_icon(user_email).should match('http://www.gravatar.com/avatar/b58c6f14d292556214bd64909bcdb118')
    end

    it "should use SSL when appropriate" do
      Gitlab.config.gitlab.stub(https: true)
      gravatar_icon(user_email).should match('https://secure.gravatar.com')
    end

    it "should return custom gravatar path when gravatar_url is set" do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      Gitlab.config.gravatar.stub(:plain_url).and_return('http://example.local/?s=%{size}&hash=%{hash}')
      gravatar_icon(user_email, 20).should == 'http://example.local/?s=20&hash=b58c6f14d292556214bd64909bcdb118'
    end

    it "should accept a custom size" do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email, 64).should match(/\?s=64/)
    end

    it "should use default size when size is wrong" do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email, nil).should match(/\?s=40/)
    end

    it "should be case insensitive" do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email).should == gravatar_icon(user_email.upcase + " ")
    end
  end

  describe "grouped_options_refs" do
    # Override Rails' grouped_options_for_select helper since HTML is harder to work with
    def grouped_options_for_select(options, *args)
      options
    end

    let(:options) { grouped_options_refs }

    before do
      # Must be an instance variable
      @project = create(:project)
    end

    it "includes a list of branch names" do
      options[0][0].should == 'Branches'
      options[0][1].should include('master', 'stable')
    end

    it "includes a list of tag names" do
      options[1][0].should == 'Tags'
      options[1][1].should include('v0.9.4','v1.2.0')
    end

    it "includes a specific commit ref if defined" do
      # Must be an instance variable
      @ref = '2ed06dc41dbb5936af845b87d79e05bbf24c73b8'

      options[2][0].should == 'Commit'
      options[2][1].should == [@ref]
    end

    it "sorts tags in a natural order" do
      # Stub repository.tag_names to make sure we get some valid testing data
      expect(@project.repository).to receive(:tag_names).and_return(["v1.0.9", "v1.0.10", "v2.0", "v3.1.4.2", "v1.0.9a"])

      options[1][1].should == ["v3.1.4.2", "v2.0", "v1.0.10", "v1.0.9a", "v1.0.9"]
    end
  end

  describe "user_color_scheme_class" do
    context "with current_user is nil" do
      it "should return a string" do
        allow(self).to receive(:current_user).and_return(nil)
        user_color_scheme_class.should be_kind_of(String)
      end
    end

    context "with a current_user" do
      (1..5).each do |color_scheme_id|
        context "with color_scheme_id == #{color_scheme_id}" do
          it "should return a string" do
            current_user = double(:color_scheme_id => color_scheme_id)
            allow(self).to receive(:current_user).and_return(current_user)
            user_color_scheme_class.should be_kind_of(String)
          end
        end
      end
    end
  end

  describe "simple_sanitize" do
    let(:a_tag) { '<a href="#">Foo</a>' }

    it "allows the a tag" do
      simple_sanitize(a_tag).should == a_tag
    end

    it "allows the span tag" do
      input = '<span class="foo">Bar</span>'
      simple_sanitize(input).should == input
    end

    it "disallows other tags" do
      input = "<strike><b>#{a_tag}</b></strike>"
      simple_sanitize(input).should == a_tag
    end
  end

  describe "link_to" do

    it "should not include rel=nofollow for internal links" do
      expect(link_to("Home", root_path)).to eq("<a href=\"/\">Home</a>")
    end

    it "should include rel=nofollow for external links" do
      expect(link_to("Example", "http://www.example.com")).to eq("<a href=\"http://www.example.com\" rel=\"nofollow\">Example</a>")
    end

    it "should include re=nofollow for external links and honor existing html_options" do
      expect(
        link_to("Example", "http://www.example.com", class: "toggle", data: {toggle: "dropdown"})
      ).to eq("<a class=\"toggle\" data-toggle=\"dropdown\" href=\"http://www.example.com\" rel=\"nofollow\">Example</a>")
    end

    it "should include rel=nofollow for external links and preserver other rel values" do
      expect(
        link_to("Example", "http://www.example.com", rel: "noreferrer")
      ).to eq("<a href=\"http://www.example.com\" rel=\"noreferrer nofollow\">Example</a>")
    end
  end
end
