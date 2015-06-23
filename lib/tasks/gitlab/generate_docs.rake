namespace :gitlab do
  desc "GitLab | Generate sdocs for project"
  task generate_docs: :environment do
    system(*%W(bundle exec sdoc -o doc/code app lib))
  end
end

