# Elasticsearch integration

If you want to make your GitLab search really powerful you can get it use the Elasticsearch.

Elasticsearch is a flexible, scalable and powerful search service. It will keep to be a fast even with huge amount of data. We use elasticsearch to search through a merge requests, issues, notes, wiki, code and commits. Once the data is added to the database it will update search index automatically.

1.  Install elasticsearch as described in the [official web site](https://www.elastic.co/products/elasticsearch). The packages are also available on different platforms.

1.  On your GitLab server, open the configuration file.

    For omnibus package:

    ```sh
      sudo editor /etc/gitlab/gitlab.rb
    ```

    For installations from source:

    ```sh
      cd /home/git/gitlab

      sudo -u git -H editor config/gitlab.yml
    ```

1.  Add the elastic search configuration:

    For omnibus package:

    ```ruby
      gitlab_rails['elasticsearch'] = [
        {
          "enabled" => "true",
          "host" => "localhost",
          "port" => 9200
        }
      ]
    ```

    For installation from source:

    ```
      elasticsearch:
        enabled: true
        host: localhost
        port: 9200
    ```


    Chose you own configuration parameters.

1.  Save the configuration file.

1.  Restart GitLab for the changes to take effect.

1.  And the last step it to index everything by running special rake tasks.
    
    To index all your repositories you should run following tasks:

    ```
    # omnibus installations
    sudo gitlab-rake gitlab:elastic:index_repositories

    # installation from source
    bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production
    ```

    Keep in mind that it will take a while depending on how huge your git repos are.

    
    To index all wikis:

    ```
    # omnibus installations
    sudo gitlab-rake gitlab:elastic:index_wikis

    # installation from source
    bundle exec rake gitlab:elastic:index_wikis RAILS_ENV=production
    ```

    To index all database entities:

    ```
    # omnibus installations
    sudo gitlab-rake gitlab:elastic:index_database

    # installation from source
    bundle exec rake gitlab:elastic:index_database RAILS_ENV=production
    ```

That's it. Enjoy you powerful search.