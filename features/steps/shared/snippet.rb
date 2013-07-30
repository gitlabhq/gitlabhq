module SharedSnippet
  include Spinach::DSL

  And 'I have gitlab public "Personal snippet one" snippet' do
    create(:personal_snippet,
           title: "Personal snippet one",
           content: "Test content",
           file_name: "snippet.rb",
           visibility: "gitlab_public",
           author: current_user)
  end

  And 'I have private "Personal snippet private" snippet' do
    create(:personal_snippet,
           title: "Personal snippet private",
           content: "Provate content",
           file_name: "private_snippet.rb",
           visibility: "private",
           author: current_user)
  end
end
