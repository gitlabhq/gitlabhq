---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Surveillez les performances des applications et résolvez les problèmes de performance.
ignore_in_report: true
title: "Configurer l'observabilité sur GitLab Self-Managed"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

Les données d'observabilité sont collectées dans une application distincte, en dehors de votre instance GitLab.com. Les problèmes liés à votre instance GitLab n'ont aucun impact sur la collecte ou la consultation de vos données d'observabilité, et vice-versa.

Pour GitLab Self-Managed, vous contrôlez l'emplacement de stockage des données.

## Workflow {#workflow}

Pour configurer l'observabilité sur votre instance GitLab Self-Managed, vous devez :

1. Vous assurer de remplir les prérequis.
1. Provisionner un serveur et un stockage.
1. Configurer Docker et installer l'observabilité dans un conteneur.
1. Configurer l'accès réseau.
1. Configurer l'URL de votre groupe.

## Prérequis {#prerequisites}

- Vous devez disposer d'une instance EC2 ou d'une machine virtuelle similaire avec :
  - Minimum : `t3.large` (2 vCPU, 8 Go de RAM).
  - Recommandé : `t3.xlarge` (4 vCPU, 16 Go de RAM) pour une utilisation en production.
  - Au moins 100 Go d'espace de stockage.
- Docker et Docker Compose doivent être installés.
- Votre version de GitLab doit être la version 18.1 ou ultérieure.
- Votre instance GitLab doit être connectée à l'instance d'observabilité.

### Provisionner le serveur et le stockage {#provision-server-and-storage}

Pour AWS EC2 :

1. Lancez une instance EC2 avec au moins 2 vCPU et 8 Go de RAM.
1. Ajoutez un volume EBS d'au moins 100 Go.
1. Connectez-vous à votre instance via SSH.

#### Monter le volume de stockage {#mount-storage-volume}

```shell
sudo mkdir -p /mnt/data
sudo mount /dev/xvdbb /mnt/data  # Replace xvdbb with your volume name
sudo chown -R $(whoami):$(whoami) /mnt/data
```

Pour un montage permanent, ajoutez à `/etc/fstab` :

```shell
echo '/dev/xvdbb /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

### Installer Docker {#install-docker}

Pour Ubuntu/Debian :

```shell
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

Pour Amazon Linux :

```shell
sudo dnf update
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

Déconnectez-vous puis reconnectez-vous, ou exécutez :

```shell
newgrp docker
```

#### Configurer Docker pour utiliser le volume monté {#configure-docker-to-use-the-mounted-volume}

```shell
sudo mkdir -p /mnt/data/docker
sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/mnt/data/docker"
}
EOF'
sudo systemctl restart docker
```

Vérifiez avec :

```shell
docker info | grep "Docker Root Dir"
```

#### Installer GitLab Observability {#install-gitlab-observability}

```shell
cd /mnt/data
git clone -b main https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y.git
cd gitlab_o11y/deploy/docker
docker-compose up -d
```

Si vous rencontrez des erreurs de délai d'attente, utilisez :

```shell
COMPOSE_HTTP_TIMEOUT=300 docker-compose up -d
```

#### Facultatif : utiliser une base de données ClickHouse externe {#optional-use-an-external-clickhouse-database}

Si vous le préférez, vous pouvez utiliser votre propre base de données ClickHouse.

Prérequis :

- Assurez-vous que votre instance ClickHouse externe est accessible et correctement configurée avec les identifiants d'authentification requis.

Avant d'exécuter `docker-compose up -d`, effectuez les étapes suivantes :

1. Ouvrez le fichier `docker-compose.yml`.
1. Commentez :
   - Les services `clickhouse` et `zookeeper`.
   - Les sections `x-clickhouse-defaults` et `x-clickhouse-depend`.
1. Remplacez toutes les occurrences de `clickhouse:9000` par votre endpoint ClickHouse et votre port TCP appropriés (par exemple, `my-clickhouse.example.com:9000`) dans les fichiers suivants. Si votre instance ClickHouse nécessite une authentification, vous devrez peut-être également mettre à jour les chaînes de connexion pour inclure les identifiants :
   - `docker-compose.yml`
   - `otel-collector-config.yaml`
   - `prometheus-config.yml`

### Configurer l'accès réseau pour GitLab Observability {#configure-network-access-for-gitlab-observability}

Pour recevoir correctement les données de télémétrie, vous devez ouvrir des ports spécifiques dans le groupe de sécurité de votre instance GitLab Observability :

1. Accédez à **AWS Console** > **EC2** > **Security Groups**.
1. Sélectionnez le groupe de sécurité associé à votre instance GitLab Observability.
1. Sélectionnez **Edit inbound rules**.
1. Ajoutez les règles suivantes :
   - Type : Custom TCP, Port : 8080, Source : votre IP ou 0.0.0.0/0 (pour l'accès à l'interface utilisateur)
   - Type : Custom TCP, Port : 4317, Source : votre IP ou 0.0.0.0/0 (pour OTLP gRPC)
   - Type : Custom TCP, Port : 4318, Source : votre IP ou 0.0.0.0/0 (pour OTLP HTTP)
   - Type : Custom TCP, Port : 9411, Source : votre IP ou 0.0.0.0/0 (pour Zipkin - facultatif)
   - Type : Custom TCP, Port : 14268, Source : votre IP ou 0.0.0.0/0 (pour Jaeger HTTP - facultatif)
   - Type : Custom TCP, Port : 14250, Source : votre IP ou 0.0.0.0/0 (pour Jaeger gRPC - facultatif)
1. Sélectionnez **Save rules**.

Accédez maintenant à l'interface utilisateur de GitLab Observability à l'adresse :

```plaintext
http://[your-instance-ip]:8080
```

### Configurer l'URL de votre groupe {#configure-the-url-for-your-group}

Configurez l'URL de GitLab Observability pour votre groupe à l'aide de la console Rails :

1. Accédez à la console Rails :

   ```shell
   docker exec -it gitlab gitlab-rails console
   ```

1. Configurez les paramètres d'observabilité pour votre groupe :

   ```ruby
   group = Group.find_by_path('your-group-name')

   Observability::GroupO11ySetting.create!(
     group_id: group.id,
     o11y_service_url: 'your-o11y-instance-url',
     o11y_service_user_email: 'your-email@example.com',
     o11y_service_password: 'your-secure-password',
     o11y_service_post_message_encryption_key: 'your-super-secret-encryption-key-here-32-chars-minimum'
   )
   ```

   Remplacez :
   - `your-group-name` par le chemin réel de votre groupe.
   - `your-o11y-instance-url` par l'URL de votre instance GitLab Observability (par exemple : `http://192.168.1.100:8080`).
   - L'adresse e-mail et le mot de passe par vos identifiants préférés.
   - La clé de chiffrement par une chaîne sécurisée d'au moins 32 caractères.

## Étapes suivantes {#next-steps}

- [Envoyer vos données de télémétrie à GitLab Observability](send.md).
- [Afficher la télémétrie des pipelines CI/CD](ci_cd.md).
- [Obtenir des informations de dépannage](troubleshooting.md).
