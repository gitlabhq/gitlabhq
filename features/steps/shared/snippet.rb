module SharedSnippet
  include Spinach::DSL

  And 'I have public "Personal snippet one" snippet' do
    create(:personal_snippet,
           title: "Personal snippet one",
           content: "Test content",
           file_name: "snippet.rb",
           private: false,
           author: current_user)
  end

  And 'I have private "Personal snippet private" snippet' do
    create(:personal_snippet,
           title: "Personal snippet private",
           content: "Provate content",
           file_name: "private_snippet.rb",
           private: true,
           author: current_user)
  end
  And 'I have a public many lined snippet' do
    create(:personal_snippet,
           title: "Many lined snippet",
           content: "line one\nline two\nline three\nline four\nline five\nline six\nline seven\nline eight\nline nine\nline ten\nline eleven\nline twelve\nline thirteen\nline fourteen",
           file_name: "many_lined_snippet.rb",
           private: true,
           author: current_user)
  end
end
