# OAuth

You can use other services to log into GitLab via oAuth.

For this you need: 

* create app in selected services
* configure gitlab.yml 

## Twitter:

Below are screenshots how to setup your app on Twitter for this:

![Application details](twitter_app_details.png)
![API Keys](twitter_app_api_keys.png)

## GitHub:

![GitHub app](github_app.png)

## Google:

![Google app](google_app.png)


## GitLab config file

Second step is to modify gitlab.yml with app credentials:

```
production:
  ...

  omniauth:
    enabled: true
  
    providers:
      - { 
        name: 'twitter',
        app_id: 'XXXXXXXX',
        app_secret: 'XXXXXXXXXXXXXXXXXXXXXXXX'
        }
      - { 
        name: 'google_oauth2',
        app_id: 'XXXXXXXXXXX.apps.googleusercontent.com',
        app_secret: 'XXXXXXXX'
        }
      - { 
        name: 'github',
        app_id: 'XXXXXXXXXX',
        app_secret: 'XXXXXXXXXXXXXXXXXXXXXXXX'
        }

```

