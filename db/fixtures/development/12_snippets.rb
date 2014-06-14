Gitlab::Seeder.quiet do
  contents = [
    `curl https://gist.githubusercontent.com/randx/4275756/raw/da2f262920c96d1a970d48bf2e99147954b1f4bd/glus1204.sh`,
    `curl https://gist.githubusercontent.com/randx/3754594/raw/11026a295e6ef3a151c635707a3e1e8e15fc4725/gitlab_setup.sh`,
    `curl https://gist.githubusercontent.com/randx/3065552/raw/29fbd09f4605a5ea22a5a9095e35fd1938dea4d6/gistfile1.sh`,
  ]

  (1..50).each  do |i|
    user = User.all.sample

    PersonalSnippet.seed(:id, [{
      id: i,
      author_id: user.id,
      title: Faker::Lorem.sentence(3),
      file_name:  Faker::Internet.domain_word + '.sh',
      private: [true, false].sample,
      content: contents.sample,
    }])
    print('.')
  end
end

