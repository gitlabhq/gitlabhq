---
stage: none
group: Embody
info: This page is owned by https://handbook.gitlab.com/handbook/ceo/office-of-the-ceo/embody-team/
description: Monitor application performance and troubleshoot performance issues.
ignore_in_report: true
title: Observability
---

{{< details >}}

- Tier: Free
- Offering: GitLab Self-Managed
- Status: Experimental

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/experimental-observability/documentation/-/issues/6) in GitLab 18.1. This feature is an [experiment](../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Use GitLab Observability (O11y) to:

- Monitor application performance through a unified observability dashboard.
- View distributed traces, logs, and metrics in a single platform.
- Identify and troubleshoot performance bottlenecks in your applications.

{{< alert type="disclaimer" />}}

By adding observability to GitLab itself users can gain [these (planned) features](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/8).

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab Experimental Observability (O11y) Introduction](https://www.youtube.com/watch?v=XI9ZruyNEgs).
<!-- Video published on 2025-06-18 -->

Join the conversation about interesting ways to use GitLab O11y in the GitLab O11y [Discord channel](https://discord.com/channels/778180511088640070/1379585187909861546).

## Set up a GitLab Observability instance

Prerequisites:

- You must have an EC2 instance or similar virtual machine with:
  - Minimum: t3.large (2 vCPU, 8 GB RAM).
  - Recommended: t3.xlarge (4 vCPU, 16 GB RAM) for production use.
  - At least 100 GB storage space.
- Docker and Docker Compose must be installed.
- Your GitLab instance must be connected to the Observability instance.

### Provision server and storage

For AWS EC2:

1. Launch an EC2 instance with at least 2 vCPU and 8 GB RAM.
1. Add an EBS volume of at least 100 GB.
1. Connect to your instance using SSH.

### Mount storage volume

```shell
sudo mkdir -p /mnt/data
sudo mount /dev/xvdbb /mnt/data  # Replace xvdbb with your volume name
sudo chown -R $(whoami):$(whoami) /mnt/data
```

For permanent mounting, add to `/etc/fstab`:

```shell
echo '/dev/xvdbb /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

### Install Docker

For Ubuntu/Debian:

```shell
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

For Amazon Linux:

```shell
sudo dnf update
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

Log out and log back in, or run:

```shell
newgrp docker
```

### Configure Docker to use the mounted volume

```shell
sudo mkdir -p /mnt/data/docker
sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/mnt/data/docker"
}
EOF'
sudo systemctl restart docker
```

Verify with:

```shell
docker info | grep "Docker Root Dir"
```

### Install GitLab Observability

```shell
cd /mnt/data
git clone -b main https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y.git
cd gitlab_o11y/deploy/docker
docker-compose up -d
```

If you encounter timeout errors, use:

```shell
COMPOSE_HTTP_TIMEOUT=300 docker-compose up -d
```

### Configure network access for GitLab Observability

To properly receive telemetry data, you need to open specific ports in your GitLab O11y instance's security group:

1. Go to **AWS Console > EC2 > Security Groups**.
1. Select the security group attached to your GitLab O11y instance.
1. Select **Edit inbound rules**.
1. Add the following rules:
   - Type: Custom TCP, Port: 8080, Source: Your IP or 0.0.0.0/0 (for UI access)
   - Type: Custom TCP, Port: 4317, Source: Your IP or 0.0.0.0/0 (for OTLP gRPC)
   - Type: Custom TCP, Port: 4318, Source: Your IP or 0.0.0.0/0 (for OTLP HTTP)
   - Type: Custom TCP, Port: 9411, Source: Your IP or 0.0.0.0/0 (for Zipkin - optional)
   - Type: Custom TCP, Port: 14268, Source: Your IP or 0.0.0.0/0 (for Jaeger HTTP - optional)
   - Type: Custom TCP, Port: 14250, Source: Your IP or 0.0.0.0/0 (for Jaeger gRPC - optional)
1. Select **Save rules**.

### Access GitLab Observability

Access the GitLab O11y UI at:

```plaintext
http://[your-instance-ip]:8080
```

## Connect GitLab to GitLab Observability

### Configure GitLab

Add the GitLab O11y URL as an environment variable to your GitLab instance:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['env'] = {
     'O11Y_URL' => 'http://[your-o11y-instance-ip]:8080'
   }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  gitlab/gitlab-ce:latest
```

The `O11Y_URL` environment variable must be configured in the GitLab configuration file:

1. Access the container:

   ```shell
   docker exec -it gitlab /bin/bash
   ```

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['env'] = {
     'O11Y_URL' => 'http://[your-o11y-instance-ip]:8080'
   }
   ```

1. Reconfigure GitLab:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Enable the feature flag

The Observability feature is behind a feature flag. To enable it:

1. Access the Rails console:

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rails console
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   docker exec -it gitlab gitlab-rails console
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Enable the feature flag for your group:

   ```ruby
   Feature.enable(:observability_sass_features, Group.find_by_path('your-group-name'))
   ```

1. Verify that the feature flag is enabled:

   ```ruby
   Feature.enabled?(:observability_sass_features, Group.find_by_path('your-group-name'))
   # Should return true
   ```

## Use Observability with GitLab

After you have configured GitLab O11y, to access the dashboard embedded in GitLab:

1. On the left sidebar, select **Search or go to** and find your group where the feature flag is enabled.
1. On the left sidebar, select **Observability**.

If **Observability** isn't displayed on the left sidebar,
go directly to `http://<gitlab_instance>/groups/<group_path>/-/observability/services`.

![GitLab Experimental Observability example](img/gitLab_o11y_example_v18_1.png "GitLab Observability Example")

## Send telemetry data to GitLab Observability

You can test your GitLab O11y installation by sending sample telemetry data using the OpenTelemetry SDK. This example uses Ruby, but OpenTelemetry has SDKs for many languages.

Prerequisites:

- Ruby installed on your local machine
- Required gems:

  ```shell
  gem install opentelemetry-sdk opentelemetry-exporter-otlp
  ```

### Create a basic test script

Create a file named `test_o11y.rb` with the following content:

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
  # Define service information
  resource = OpenTelemetry::SDK::Resources::Resource.create({
    'service.name' => 'test-service',
    'service.version' => '1.0.0',
    'deployment.environment' => 'production'
  })
  c.resource = resource

  # Configure OTLP exporter to send to GitLab O11y
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'http://[your-o11y-instance-ip]:4318/v1/traces'
      )
    )
  )
end

# Get tracer and create spans
tracer = OpenTelemetry.tracer_provider.tracer('basic-demo')

# Create parent span
tracer.in_span('parent-operation') do |parent|
  parent.set_attribute('custom.attribute', 'test-value')
  puts "Created parent span: #{parent.context.hex_span_id}"

  # Create child span
  tracer.in_span('child-operation') do |child|
    child.set_attribute('custom.child', 'child-value')
    puts "Created child span: #{child.context.hex_span_id}"
    sleep(1)
  end
end

puts "Waiting for export..."
sleep(5)
puts "Done!"
```

Replace `[your-o11y-instance-ip]` with your GitLab O11y instance's IP address or hostname.

### Run the test

1. Run the script:

   ```shell
   ruby test_o11y.rb
   ```

1. Check your GitLab O11y dashboard:
   - Open `http://[your-o11y-instance-ip]:8080`
   - Go to the "Services" section
   - Look for the "test-service" service
   - Select on it to see traces and spans

## Instrument your application

To add OpenTelemetry instrumentation to your applications:

1. Add the OpenTelemetry SDK for your language.
1. Configure the OTLP exporter to point to your GitLab O11y instance.
1. Add spans and attributes to track operations and metadata.

Refer to the [OpenTelemetry documentation](https://opentelemetry.io/docs/instrumentation/) for language-specific guidelines.

## Troubleshooting

### GitLab Observability instance issues

Check container status:

```shell
docker ps
```

View container logs:

```shell
docker logs [container_name]
```

### Menu doesn't appear

1. Verify the feature flag is enabled for your group:

   ```ruby
   Feature.enabled?(:observability_sass_features, Group.find_by_path('your-group-name'))
   ```

1. Check that the O11Y_URL environment variable is set:

   ```ruby
   ENV['O11Y_URL']
   ```

1. Ensure the routes are properly registered:

   ```ruby
   Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('observability') }.map(&:path)
   ```

### Performance issues

If experiencing SSH connection issues or poor performance:

- Verify instance type meets minimum requirements (2 vCPU, 8 GB RAM)
- Consider resizing to a larger instance type
- Check disk space and increase if needed

### Telemetry doesn't show up

If your telemetry data isn't appearing in GitLab O11y:

1. Verify ports 4317 and 4318 are open in your security group.
1. Test connectivity with:

   ```shell
   nc -zv [your-o11y-instance-ip] 4317
   nc -zv [your-o11y-instance-ip] 4318
   ```

1. Check container logs for any errors:

   ```shell
   docker logs otel-collector-standard
   docker logs o11y-otel-collector
   docker logs o11y
   ```

1. Try using the HTTP endpoint (4318) instead of gRPC (4317).
1. Add more debugging information to your OpenTelemetry setup.
