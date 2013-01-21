namespace :gitlab do
  desc "GITLAB | Generate sdocs for project"
  task generate_docs: :environment do
    system("bundle exec sdoc -o doc/code app lib")
  end
end

