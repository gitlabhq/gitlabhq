## jenkins_client

For use with [this jenkins docker image](https://gitlab.com/gitlab-org/quality/third-party-docker-images/jenkins)

### usage

instantiate client

```ruby
client = Jenkins::Client.new(
    '127.0.0.1',
    user: ENV['JENKINS_ADMIN_USER'],
    password: ENV['JENKINS_ADMIN_PASS'],
)
```

configure gitlab plugin and create a job

```ruby
connection_name = 'gitlab-connection'

client.configure_gitlab_plugin(
  ENV['GITLAB_URL'],
  connection_name: connection_name,
  access_token: ENV['GITLAB_ACCESS_TOKEN'],
  read_timeout: 20,
  connection_timeout: 10
)

job = client.create_job 'Job Name' do |job|
  job.gitlab_connection = connection_name
  job.description = 'Job Description'
  job.repo_url = 'https://location-of-project.git'
  job.shell_command = 'sleep 20'
end
```

view info about the job

```ruby
while job.running?
  puts "Number of active builds: #{job.active_runs}"
end

puts "Last build status #{job.status}"
puts "Last build log #{job.log}"
```

### developer notes

This client makes extensive use of the [/script api](https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/client-and-managed-masters/execute-groovy-with-a-rest-call).

Groovy is a dynamic language hosted on the Java platform. Please refer to https://learnxinyminutes.com/docs/groovy/ for basic syntax.

The scripts may reference the code api of jenkins and the gitlab jenkins plugin.  Here are some articles and source files to reference when debugging.

* [Setting Jenkins Credentials](https://nickcharlton.net/posts/setting-jenkins-credentials-with-groovy.html)
* [GitLabConnectionConfig](https://github.com/jenkinsci/gitlab-plugin/blob/master/src/main/java/com/dabsquared/gitlabjenkins/connection/GitLabConnectionConfig.java) and [GitLabConnection](https://github.com/jenkinsci/gitlab-plugin/blob/master/src/main/java/com/dabsquared/gitlabjenkins/connection/GitLabConnection.java)
* [Jenkins.instance.getProjects](https://github.com/jenkinsci/jenkins/blob/master/core/src/main/java/jenkins/model/Jenkins.java#L1878)
* [Job.getBuilds](https://github.com/jenkinsci/jenkins/blob/master/core/src/main/java/hudson/model/Job.java#L734)
* [Run.getResult](https://github.com/jenkinsci/jenkins/blob/master/core/src/main/java/hudson/model/Run.java#L491)
