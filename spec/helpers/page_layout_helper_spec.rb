require 'rails_helper'

describe PageLayoutHelper do
  describe 'page_description' do
    it 'defaults to value returned by page_description_default helper' do
      allow(helper).to receive(:page_description_default).and_return('Foo')

      expect(helper.page_description).to eq 'Foo'
    end

    it 'returns the last-pushed description' do
      helper.page_description('Foo')
      helper.page_description('Bar')
      helper.page_description('Baz')

      expect(helper.page_description).to eq 'Baz'
    end

    it 'squishes multiple newlines' do
      helper.page_description("Foo\nBar\nBaz")

      expect(helper.page_description).to eq 'Foo Bar Baz'
    end

    it 'truncates' do
      helper.page_description <<-LOREM.strip_heredoc
        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
        ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
        dis parturient montes, nascetur ridiculus mus. Donec quam felis,
        ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa
        quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget,
        arcu.
      LOREM

      expect(helper.page_description).to end_with 'quam felis,...'
    end

    it 'sanitizes all HTML' do
      helper.page_description("<b>Bold</b> <h1>Header</h1>")

      expect(helper.page_description).to eq 'Bold Header'
    end
  end

  describe 'page_description_default' do
    it 'uses Project description when available' do
      project = double(description: 'Project Description')
      helper.instance_variable_set(:@project, project)

      expect(helper.page_description_default).to eq 'Project Description'
    end

    it 'uses brand_title when Project description is nil' do
      project = double(description: nil)
      helper.instance_variable_set(:@project, project)

      expect(helper).to receive(:brand_title).and_return('Brand Title')
      expect(helper.page_description_default).to eq 'Brand Title'
    end

    it 'falls back to brand_title' do
      allow(helper).to receive(:brand_title).and_return('Brand Title')

      expect(helper.page_description_default).to eq 'Brand Title'
    end
  end

  describe 'page_image' do
    it 'defaults to the GitLab logo' do
      expect(helper.page_image).to end_with 'assets/gitlab_logo.png'
    end

    context 'with @project' do
      it 'uses Project avatar if available' do
        project = double(avatar_url: 'http://example.com/uploads/avatar.png')
        helper.instance_variable_set(:@project, project)

        expect(helper.page_image).to eq project.avatar_url
      end

      it 'falls back to the default' do
        project = double(avatar_url: nil)
        helper.instance_variable_set(:@project, project)

        expect(helper.page_image).to end_with 'assets/gitlab_logo.png'
      end
    end

    context 'with @user' do
      it 'delegates to avatar_icon helper' do
        user = double('User')
        helper.instance_variable_set(:@user, user)

        expect(helper).to receive(:avatar_icon).with(user)

        helper.page_image
      end
    end
  end
end
