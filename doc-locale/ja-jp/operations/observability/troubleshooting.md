---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: アプリケーションのパフォーマンスを監視し、パフォーマンスイシューのトラブルシューティングを行う。
ignore_in_report: true
title: 可観測性のトラブルシューティング
---


{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

可観測性を使用する際に、次のイシューに遭遇する可能性があります。

## GitLab可観測性インスタンスの問題 {#gitlab-observability-instance-issues}

コンテナのステータスを確認してください:

```shell
docker ps
```

コンテナのログを表示してください:

```shell
docker logs [container_name]
```

## メニューが表示されない {#menu-doesnt-appear}

1. グループに可観測性サービスURLが設定されていることを確認してください:

   ```ruby
   group = Group.find_by_path('your-group-name')
   group.observability_group_o11y_setting&.o11y_service_url
   ```

1. ルートが正しく登録されていることを確認してください:

   ```ruby
   Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('observability') }.map(&:path)
   ```

## パフォーマンスの問題 {#performance-issues}

SSH接続イシューが発生している場合、またはパフォーマンスが低い場合:

- インスタンスタイプが最小要件（2 vCPU、8 GB RAM）を満たしていることを確認してください。
- より大きなインスタンスタイプへのサイズ変更を検討してください。
- ディスク領域を確認し、必要に応じて増やしてください。

## テレメトリーが表示されない {#telemetry-doesnt-show-up}

GitLab可観測性にテレメトリデータが表示されない場合:

1. セキュリティグループでポート4317および4318が開いていることを確認してください。
1. 接続をテストしてください:

   ```shell
   nc -zv [your-o11y-instance-ip] 4317
   nc -zv [your-o11y-instance-ip] 4318
   ```

1. コンテナログにエラーがないか確認してください:

   ```shell
   docker logs otel-collector-standard
   docker logs o11y-otel-collector
   docker logs o11y
   ```

1. gRPC (4317) の代わりにHTTPエンドポイント (4318) を使用してみてください。
1. OpenTelemetryセットアップに、より多くのデバッグ情報を追加してください。
