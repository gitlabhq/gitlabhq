require 'rails_helper'

feature 'Search Snippets' do
  scenario 'User searches for snippets by title' do
    public_snippet = create(:personal_snippet, :public, title: 'Beginning and Middle')
    private_snippet = create(:personal_snippet, :private, title: 'Middle and End')

    sign_in private_snippet.author
    visit dashboard_snippets_path

    page.within '.search' do
      fill_in 'search', with: 'Middle'
      click_button 'Go'
    end

    click_link 'Titles and Filenames'

    expect(page).to have_link(public_snippet.title)
    expect(page).to have_link(private_snippet.title)
  end

  scenario 'User searches for snippet contents' do
    create(:personal_snippet,
           :public,
           title: 'Many lined snippet',
           content: <<-CONTENT.strip_heredoc
             |line one
             |line two
             |line three
             |line four
             |line five
             |line six
             |line seven
             |line eight
             |line nine
             |line ten
             |line eleven
             |line twelve
             |line thirteen
             |line fourteen
           CONTENT
          )

    sign_in create(:user)
    visit dashboard_snippets_path

    page.within '.search' do
      fill_in 'search', with: 'line seven'
      click_button 'Go'
    end

    expect(page).to have_content('line seven')

    # 3 lines before the matched line should be visible
    expect(page).to have_content('line six')
    expect(page).to have_content('line five')
    expect(page).to have_content('line four')
    expect(page).not_to have_content('line three')

    # 3 lines after the matched line should be visible
    expect(page).to have_content('line eight')
    expect(page).to have_content('line nine')
    expect(page).to have_content('line ten')
    expect(page).not_to have_content('line eleven')
  end
end
