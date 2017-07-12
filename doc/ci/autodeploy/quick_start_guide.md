# Auto deploy: quick start guide

This guide is step-by-step instruction about how to deploy the GitLab.com project to Google Cloud by using GitLab Auto Deploy feature.

We made a Ruby application to use as example for this guide. It contains several files we need to make auto deploy possible. 

* `server.rb` - our application. It will start http server on port 5000 and renders “Hello, world!” 
* `Dockerfile` - to build our app into container. It will use ruby image and run `server.rb`
* `.gitlab-ci.yml` - GitLab CI config file with only 2 jobs: build docker image and deploy it to kubernetes

Those are absolute minimal requirement to have your application automatically build and deployed to Google Container Engine every time you push to the repository. 

### Fork sample project on GitLab.com

Let’s start with forking our sample application. Go to [the project page](https://gitlab.com/gitlab-examples/ruby-autodeploy) and press fork button. In few minutes you should have a project under your namespace with all necessary files.  

### Setup your own cluster on Google Container Engine

We assume you already have account for https://console.cloud.google.com. If not - you need to create one. 

Visit “Container Engine” tab and create new cluster. You can change only name and keep the rest of the settings by default.  Once you have your cluster running you need to connect to the cluster by following Google interface.

### Connect to Kubernetes cluster

You need to have the Google Cloud SDK installed. e.g.
On OSX, install [homebrew](https://brew.sh) for all the things:

1. Install Brew Caskroom `brew install caskroom/cask/brew-cask`
2. Install Google Cloud SDK `brew cask install google-cloud-sdk`
3. Run `gcloud components install kubectl`

Connect to the cluster and open Kubernetes Dashboard ![connect to cluster](img/guide_connect_cluster.png)


### Copy credentials to GitLab.com

Once you have Kubernetes Dashboard interface running you should visit “Secrets” link under “Config” section. There you should find 3 setting we need for GitLab integration: ca.crt, namespace, token.

![connect to cluster](img/guide_secret.png)

You need to copy-paste those values in your project on GitLab.com in Kubernetes integration page. 

![connect to cluster](img/guide_integration.png)

For API URL setting you should use “Endpoint” IP from your cluster page on Google Cloud Platform. That will ensure GitLab.com can deploy container to your cluster at Google Container Engine. 
Build and run your code
Now we are going to make a change in the source code. It will create CI jobs and get your application build and deployed. Visit GitLab.com project and edit `.gitlab-ci.yml`. Replace `example.com` and `production.example.com` with your domain names.  

Once submitted, your changes should create a new pipeline with 2 jobs: build and deploy. Build job will create a docker image with your new change and push to GitLab Container Registry. Deploy job will run this image on your cluster. Once deploy job succeed you should be able to see your application by visiting Kubernetes dashboard. It will be listed as “production” under Deployment tab. 

### Expose application to the world

In order to be able to visit our application we need to install nginx ingress controller and point your domain name to external ip. 

#### Set up Ingress controller

You’ll need to make sure you have an ingress controller. If you don’t have one, do:

```sh
brew install kubernetes-helm
helm init
helm install --name production stable/nginx-ingress
```

This should create several services including `production-nginx-ingress-controller`. You can list services by running `kubectl get svc` to confirm that.

#### Point DNS at Cluster IP

Find out external IP address of the `production-nginx-ingress-controller` by running 

```sh
kubectl get svc production-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Use this IP address to configure your DNS. This part heavily depends on your preferences and domain provider. But in case you are not sure, just create A record with wildcard host like `*.<your-domain>`.

Use `nslookup production.<yourdomain>` to confirm that domain is assigned to the cluster IP. 
Once its ready - just visit http://production.yourdomain.com to see “Hello, world!”

