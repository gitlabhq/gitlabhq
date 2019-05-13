namespace :gitlab do
  namespace :features do
    desc 'GitLab | Features | Enable direct Git access via Rugged for NFS'
    task enable_rugged: :environment do
      set_rugged_feature_flags(true)
      puts 'All Rugged feature flags were enabled.'
    end

    task disable_rugged: :environment do
      set_rugged_feature_flags(false)
      puts 'All Rugged feature flags were disabled.'
    end
  end

  def set_rugged_feature_flags(status)
    Gitlab::Git::RuggedImpl::Repository::FEATURE_FLAGS.each do |flag|
      if status
        Feature.enable(flag)
      else
        Feature.get(flag).remove
      end
    end
  end
end
