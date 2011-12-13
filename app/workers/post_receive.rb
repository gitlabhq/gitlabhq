class PostReceive
  def self.perform(reponame, oldrev, newrev, ref)
    puts "[#{reponame}] #{oldrev} => #{newrev} (#{ref})"
  end
end
