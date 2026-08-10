---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Surveillez les performances des applications et résolvez les problèmes de performance.
ignore_in_report: true
title: Envoyer des données de télémétrie à GitLab Observability
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

Après avoir configuré Observability, vous pouvez commencer à envoyer des données à GitLab.

Pour commencer, consultez les [données de pipeline CI/CD](ci_cd.md), [envoyez des données de test](#send-test-data) ou [utilisez des modèles](#gitlab-observability-templates).

## Afficher les données Observability {#view-observability-data}

Une fois GitLab Observability configuré :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Observability** > **Services**.
1. Sélectionnez le service dont vous souhaitez afficher les détails.

![Tableau de bord Observability de GitLab.com](img/gitLab_o11y_gitlab_com_dashboard_v18_1.png "Tableau de bord Observability de GitLab.com")

## Instrumenter votre application {#instrument-your-application}

Pour ajouter l'instrumentation OpenTelemetry à vos applications :

1. Ajoutez le SDK OpenTelemetry pour votre langage.
1. Configurez l'exportateur OTLP pour qu'il pointe vers votre instance GitLab Observability.
1. Configurez les attributs de ressource recommandés.
1. Ajoutez des spans et des attributs pour suivre les opérations et les métadonnées.

Reportez-vous à la [documentation OpenTelemetry](https://opentelemetry.io/docs/instrumentation/) pour obtenir des instructions spécifiques à chaque langage.

### Attributs de ressource recommandés {#recommended-resource-attributes}

Configurez votre SDK OpenTelemetry avec ces attributs de ressource pour lier les données de télémétrie à votre projet et à votre code GitLab. Cela permet d'activer des fonctionnalités telles que la corrélation des traces avec les commits et la création automatisée de tickets à partir des exceptions.

| Attribut de ressource | Variable CI/CD GitLab | Description |
| --- | --- | --- |
| `gitlab.project.id` | `CI_PROJECT_ID` | Lie la télémétrie au projet GitLab. Requis pour l'intégration GitLab Duo. |
| `gitlab.project.name` | `CI_PROJECT_NAME` | Nom du projet lisible par l'utilisateur, affiché dans les tableaux de bord. |
| `service.version` | `CI_COMMIT_SHA` | Le SHA du commit du code en cours d'exécution. Vous permet de corréler les traces et les erreurs avec la version exacte déployée. |
| `deployment.environment.name` | `CI_ENVIRONMENT_NAME` | L'environnement dans lequel le code s'exécute (par exemple, `production` ou `staging`). |

`service.version` et `deployment.environment.name` sont des [conventions sémantiques OpenTelemetry](https://opentelemetry.io/docs/specs/semconv/resource/). Les attributs `gitlab.*` utilisent un espace de nommage fournisseur pour le contexte spécifique à GitLab.

Les quatre variables CI/CD sont [prédéfinies dans GitLab CI/CD](../../ci/variables/predefined_variables.md) et ne nécessitent aucune configuration supplémentaire lorsque votre application s'exécute dans un pipeline. Pour le développement local, définissez ces variables d'environnement manuellement ou acceptez les valeurs par défaut vides.

L'exemple Ruby suivant illustre la configuration de ces attributs :

```ruby
OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    'gitlab.project.id'           => ENV.fetch('CI_PROJECT_ID', ''),
    'gitlab.project.name'         => ENV.fetch('CI_PROJECT_NAME', ''),
    'service.version'             => ENV.fetch('CI_COMMIT_SHA', ''),
    'deployment.environment.name' => ENV.fetch('CI_ENVIRONMENT_NAME', '')
  )

  c.use_all
end
```

Pour d'autres langages, définissez les mêmes attributs de ressource à l'aide du SDK OpenTelemetry de votre langage. Les noms d'attributs et les variables d'environnement sont identiques pour tous les langages.

## Envoyer des données de test {#send-test-data}

Vous pouvez tester votre installation GitLab Observability en envoyant des données de télémétrie d'exemple à l'aide du SDK OpenTelemetry. Cet exemple utilise Ruby, mais OpenTelemetry propose des [SDK pour de nombreux langages](https://opentelemetry.io/docs/instrumentation/).

### Prérequis {#prerequisites}

- Ruby installé sur votre machine locale.
- Gems requis :

  ```shell
  gem install opentelemetry-sdk opentelemetry-exporter-otlp
  ```

### Créer un script de test de base {#create-a-basic-test-script}

Créez un fichier nommé `test_o11y.rb` avec le contenu suivant :

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
  # Define service information
  resource = OpenTelemetry::SDK::Resources::Resource.create({
    'service.name' => 'test-service',
    'service.version' => '1.0.0',
    'deployment.environment.name' => 'production',
    'gitlab.project.id' => ENV.fetch('CI_PROJECT_ID', ''),
    'gitlab.project.name' => ENV.fetch('CI_PROJECT_NAME', '')
  })
  c.resource = resource

  # Configure OTLP exporter to send to GitLab Observability
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

Remplacez `[your-o11y-instance-ip]` par l'adresse IP ou le nom d'hôte de votre instance GitLab Observability.

### Exécuter le test {#run-the-test}

1. Exécutez le script :

   ```shell
   ruby test_o11y.rb
   ```

1. Accédez à **Observability** > **Services**. Sélectionnez le service `test-service` pour afficher les traces et les spans.

## Modèles GitLab Observability {#gitlab-observability-templates}

GitLab propose des modèles de tableau de bord prédéfinis pour vous aider à démarrer rapidement avec l'observabilité. Ces modèles sont disponibles dans les [modèles GitLab Observability](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/).

### Modèles disponibles {#available-templates}

**Standard OpenTelemetry dashboards** : si vous instrumentez votre application avec des bibliothèques OpenTelemetry standard, vous pouvez utiliser ces modèles de tableau de bord plug-and-play :

- Tableaux de bord de surveillance des performances des applications
- Visualisations des dépendances de services
- Suivi du taux d'erreurs et de la latence

**GitLab-specific dashboards** : lorsque vous envoyez des données GitLab OpenTelemetry à votre instance GitLab Observability, utilisez ces tableaux de bord pour obtenir des insights prêts à l'emploi :

- Métriques de performances des applications GitLab
- Surveillance de l'état des services GitLab
- Analyse des traces spécifiques à GitLab

**CI/CD observability** : le dépôt inclut un exemple de pipeline CI/CD GitLab avec une instrumentation OpenTelemetry compatible avec le fichier JSON du modèle de tableau de bord CI/CD de GitLab Observability. Cela vous aide à surveiller les performances de votre pipeline CI/CD et à identifier les goulots d'étranglement.

### Utiliser les modèles {#using-the-templates}

1. Clonez ou téléchargez les modèles depuis le dépôt.
1. Mettez à jour le nom du service dans les tableaux de bord des exemples d'applications pour qu'il corresponde à votre nom de service.
1. Importez les fichiers JSON dans votre instance GitLab Observability.
1. Configurez vos applications pour envoyer des données de télémétrie à l'aide des bibliothèques OpenTelemetry standard, comme décrit dans la section [Instrumenter votre application](#instrument-your-application).
1. Les tableaux de bord sont désormais disponibles avec les données de télémétrie de votre application dans GitLab Observability.

## Sujets connexes {#related-topics}

- [Dépannage d'Observability](troubleshooting.md)
