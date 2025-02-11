---
stage: Verify
group: tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Create and deploy a web service with the Google Cloud Run component'
---

Learn how to use the [Google Cloud Run component](https://gitlab.com/google-gitlab-components/cloud-run) to deploy a web service from a container image stored in Artifact Registry.

## Before you begin

1. Follow the instructions in [Set up the Google Cloud integration](../set_up_gitlab_google_integration/_index.md) to:

   - Set up Google Cloud IAM.
   - Connect GitLab to Google Artifact Registry.
   - Set up GitLab Runner to execute your CI/CD jobs on Google Cloud.

1. To run the commands on this page, set up the `gcloud` CLI in one of the following development environments:

   - [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell)
   - [Local shell](https://cloud.google.com/sdk/docs/install)

1. Set your default Google Cloud project by running the following command:

   ```shell
   gcloud config set project PROJECT_ID
   ```

   After you set your default project, you don't need to pass the `--project` flag with `gcloud` commands.

1. Enable the Compute Engine and Cloud Run APIs:

   ```shell
   gcloud services enable compute.googleapis.com artifactregistry.googleapis.com run.googleapis.com
   ```

1. Grant the following roles to your workload identity pool:

   - Cloud Storage Admin (`roles/run.admin`) to get, create, and update a service.
   - Service Account users (`roles/iam.serviceAccountUser`) to run operations as the service account

   Run the following commands to grant the `roles/run.admin` and `roles/iam.serviceAccountUser` roles to all principals in your
   workload identity pool matching `developer_access=true` attribute mapping:

   ```shell
   # Replace ${PROJECT_ID}, ${PROJECT_NUMBER}, ${LOCATION}, ${POOL_ID} with your values below
   WORKLOAD_IDENTITY=principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.developer_access/true
   gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="${WORKLOAD_IDENTITY}" --role="roles/run.admin"
   gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="${WORKLOAD_IDENTITY}" --role="roles/iam.serviceAccountUser"
   ```

## Configure the IAM integration in a new GitLab project

After you have set up the Google IAM for the integration for your organization or group, you can
reuse the integration in new projects in that organization or group:

1. [Create a new GitLab project](../../user/project/_index.md) in your organization or group.
1. In your GitLab project, select **Settings > Integrations**.
1. Select **Google Cloud IAM**.
1. In the **Google Cloud project** section, enter the following:

   - **Project ID**: the Google Cloud project ID for your workload identity pool
   - **Project number**: the Google Cloud project number for the same project

   To find the Google Cloud project ID and number, see [Identifying projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).

1. In the **Workload identity federation** section, enter the following:

   - **Pool ID**: the name you gave your workload identity pool.
   - **Provider ID**: the name you gave your OIDC provider.

   Hint: you can copy these values from the GitLab project you originally used to set up the integration.

1. Select **Save changes**. Don't run the provided script, because it creates a workload identity pool, and you already have one.

## Configure the Google Artifact Registry integration in a new GitLab project

You can store multiple container images in Artifact Registry. To reuse the same repository for
a new GitLab project, configure the Google Artifact Management integration in your project.

1. In your GitLab project, select **Settings > Integrations**.
1. Select **Google Artifact Management**
1. In the **Repository** section, enter the following:

   - **Google Cloud project ID**: the project ID for the Artifact Registry repository you want to use
   - **Repository name**: the repository name
   - **Repository location**: the location of your repository

1. Select **Save changes**. Don't run the provided script, because your workload identity pool already grants
   GitLab users in your group or organization the Artifact Registry Reader and Writer role.

## Clone your GitLab repository

To use SSH or HTTPS to clone your GitLab repository to your working environment, follow the instructions in
[Clone a Git repository to your local computer](../../topics/git/clone.md).

## Create a Dockerfile

1. In your cloned repository, create a new file named `Dockerfile`.
1. Copy and paste the following into your `Dockerfile`:

   ```dockerfile
   FROM python:3.12.4

   ARG name

   RUN mkdir web

   RUN cat <<EOF > web/index.html
   <!DOCTYPE html>
   <html>
       <head>
           <title>Home</title>
       </head>
       <body>
           <h1 color="green">Welcome to $name</h1>
       </body>
   </html>
   EOF

   CMD ["python3", "-m", "http.server", "8080", "-d", "web"]
   ```

1. Add your `Dockerfile` to Git, commit, and push to your GitLab repository:

   ```shell
   git add Dockerfile
   git commit -m "add dockerfile"
   git push
   ```

   You are prompted to enter your username and
   [personal access token](../../user/profile/personal_access_tokens.md).

The Dockerfile creates an HTTP web service.

## Create a pipeline

Create a pipeline that builds your Docker image, pushes it to the GitLab container
registry, copies the image to Google Artifact Registry, and uses Cloud Run to deploy on
Google Cloud infrastructure.

1. In your GitLab project, create a
   [`.gitlab-ci.yml` file](../../ci/quick_start/_index.md#create-a-gitlab-ciyml-file).

1. To create a pipeline that builds your image, pushes it to the GitLab container
   registry, copies it to Google Artifact Registry, and uses Cloud Run to deploy,
   modify the contents of your `.gitlab-ci.yml` file to resemble the following.

   In the following example, replace the following:

   - `LOCATION`: the Google Cloud region where you created your Google Artifact Registry repository.
   - `PROJECT`: your Google Cloud project ID for your Artifact Registry repository.
   - `REPOSITORY`: the repository ID of your Google Artifact Registry repository.

   ```yaml
   variables:
     IMAGE_TAG: v$CI_PIPELINE_ID
     AR_IMAGE: LOCATION-docker.pkg.dev/PROJECT/REPOSITORY/python-service

   stages:
     - build
     - push
     - deploy

   build-job:
     stage: build
     services:
       - docker:24.0.5-dind
     image: docker:git
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
     script:
       - docker build -t $CI_REGISTRY_IMAGE:$IMAGE_TAG --build-arg="name=Cloud Run" .
       - docker push $CI_REGISTRY_IMAGE:$IMAGE_TAG

   include:
     - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@0.1.0
       inputs:
         stage: push
         source: $CI_REGISTRY_IMAGE:$IMAGE_TAG
         target: $AR_IMAGE:$IMAGE_TAG

     - component: gitlab.com/google-gitlab-components/cloud-run/deploy-cloud-run@0.1.0
       inputs:
         stage: deploy
         image: $AR_IMAGE:$IMAGE_TAG
         project_id: PROJECT
         region: LOCATION
         service: python-service

   ```

1. Add your `.gitlab-ci.yml` file to Git, commit, and push to your GitLab repository.

The pipeline completes the following:

- Builds the image `python-service` with Docker-in-Docker.
- Stores the image in the GitLab container registry.
- Pushes the image to Google Artifact Registry with the
  [Google Artifact Registry GitLab component](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry).
- Deploys `python-service` with the [Google Cloud Run component](https://gitlab.com/google-gitlab-components/cloud-run).

## View your service in Google Cloud Run

1. In the Google Cloud Console, go to the [Cloud Run page](https://console.cloud.google.com/run).
1. Select the service you created in the **Services** tab.

   The service **Metrics** tab is displayed, and you can view service Region, URL, and other details.

## Proxy your service to view

The service is private, so you can't view it from the URL listed in the Google Cloud Console without authenticating.
To test the service, you can use the `gcloud` CLI to authenticate and proxy the service to `http://localhost:8080`.

Run the following command to proxy your service locally:

```shell
gcloud run services proxy SERVICE \
    --project PROJECT_ID \
    --region=LOCATION
```

You can view the welcome page at `http://localhost:8080`.

## Clean up

To avoid incurring charges to your Google Cloud account for the resources used
on this page, you can delete your Google Cloud resources, or your entire Google Cloud project.

If you delete the project containing your workload identity pool, you can't use the integration
unless you follow all the set up instructions again.

For information on GitLab and Google pricing and project management, see the following
resources:

- [GitLab pricing](https://about.gitlab.com/free-trial/devsecops)
- [Google pricing](https://cloud.google.com/pricing)
- [Delete a GitLab project](../../user/project/working_with_projects.md#delete-a-project)

### Delete your Google Artifact Registry repository

To delete your Google Artifact Registry repository follow the steps in this section. If you want to delete
your entire Google Cloud project, follow the steps in
[Delete your project](#delete-your-google-cloud-project).

Before you remove the repository, ensure that any images you want to keep
are available in another location.

To delete your repository, run the following command:

```shell
gcloud artifacts repositories delete REPOSITORY \
    --location=LOCATION
```

Replace the following:

- `REPOSITORY` with your Google Artifact Registry repository ID
- `LOCATION` with the location of your repository

### Delete your Cloud Run service

1. In the Google Cloud Console, go to the [Cloud Run page](https://console.cloud.google.com/run).
1. Select the checkbox next to your service.
1. Select **Delete**.

### Delete your Google Cloud project

**Caution**: Deleting a project has the following effects:

- **Everything in the project is deleted.** If you used an existing project for the tasks in this document, when
  you delete it, you also delete any other work you've done in the project.
- **Custom project IDs are lost.** When you created this project, you might have created a custom project ID that
  you want to use in the future. To preserve the URLs that use the project ID, such as an appspot.com URL, delete selected
  resources inside the project instead of deleting the whole project.

If you plan to explore multiple architectures, tutorials, or quick start tutorials on Google Cloud, reusing projects can help you
avoid exceeding project quota limits.

1. In the Google Cloud console, go to the [**Manage resources** page](https://console.cloud.google.com/iam-admin/projects).
1. In the project list, select the project that you want to delete, and then select **Delete**.
1. In the dialog, type the project ID, and then select **Shut down** to delete the project.

## Related topics

- [Learn more about Cloud Run](https://cloud.google.com/run/docs/overview/what-is-cloud-run).
