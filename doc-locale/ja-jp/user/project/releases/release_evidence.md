---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: リリースエビデンス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リリースが作成されるたびに、GitLabは関連するデータのスナップショットを取得します。このデータはJSONファイルに保存され、*リリースエビデンス*と呼ばれます。この機能には、テストアーティファクトとリンクされたマイルストーンが含まれており、外部監査のような内部プロセスを促進します。

リリースエビデンスにアクセスするには、Releasesページで、**エビデンス一覧**の見出しの下に記載されているJSONファイルへのリンクを選択します。

既存のリリースのリリースエビデンスを生成するために、[API](../../../api/releases/_index.md#collect-release-evidence)を使用することもできます。このため、各リリースは複数のリリースエビデンススナップショットを持つことができます。リリースエビデンスとその詳細はReleasesページで確認できます。

イシュートラッカーが無効になっている場合、リリースエビデンスは[ダウンロードできません](https://gitlab.com/gitlab-org/gitlab/-/issues/208397)。

以下はリリースエビデンスオブジェクトの例です:

```json
{
  "release": {
    "id": 5,
    "tag_name": "v4.0",
    "name": "New release",
    "project": {
      "id": 20,
      "name": "Project name",
      "created_at": "2019-04-14T11:12:13.940Z",
      "description": "Project description"
    },
    "created_at": "2019-06-28 13:23:40 UTC",
    "description": "Release description",
    "milestones": [
      {
        "id": 11,
        "title": "v4.0-rc1",
        "state": "closed",
        "due_date": "2019-05-12 12:00:00 UTC",
        "created_at": "2019-04-17 15:45:12 UTC",
        "description": "milestone description",
      },
      {
        "id": 12,
        "title": "v4.0-rc2",
        "state": "closed",
        "due_date": "2019-05-30 18:30:00 UTC",
        "created_at": "2019-04-17 15:45:12 UTC",
        "description": "milestone description",
      }
    ],
    "report_artifacts": [
      {
        "url":"https://gitlab.example.com/root/project-name/-/jobs/111/artifacts/download"
      }
    ]
  }
}
```

## リリースエビデンスを収集する {#collect-release-evidence}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リリースが作成されると、リリースエビデンスは自動的に収集されます。それ以外のときにエビデンスの収集を開始するには、[APIコール](../../../api/releases/_index.md#collect-release-evidence)を使用します。1つのリリースに対して、リリースエビデンスを複数回収集できます。

エビデンス収集のスナップショットは、エビデンスが収集されたタイムスタンプとともに、Releasesページに表示されます。

## レポートアーティファクトをリリースエビデンスとして含める {#include-report-artifacts-as-release-evidence}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リリースを作成する際、最後に実行されたパイプラインに[ジョブアーティファクト](../../../ci/yaml/_index.md#artifactsreports)が含まれている場合、それらはリリースにリリースエビデンスとして自動的に含まれます。

ジョブアーティファクトは通常期限切れになりますが、リリースエビデンスに含まれるアーティファクトは期限切れになりません。

ジョブアーティファクトの収集を有効にするには、両方を指定する必要があります:

1. [`artifacts:paths`](../../../ci/yaml/_index.md#artifactspaths)
1. [`artifacts:reports`](../../../ci/yaml/_index.md#artifactsreports)

```yaml
ruby:
  script:
    - gem install bundler
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

パイプラインが正常に実行された場合、リリースを作成すると、`rspec.xml`ファイルはリリースエビデンスとして保存されます。

[リリースエビデンス収集をスケジュール](#schedule-release-evidence-collection)した場合、エビデンス収集の時点で一部のアーティファクトはすでに期限切れになっている可能性があります。これを回避するには、[`artifacts:expire_in`](../../../ci/yaml/_index.md#artifactsexpire_in)キーワードを使用できます。詳細については、[イシュー222351](https://gitlab.com/gitlab-org/gitlab/-/issues/222351)を参照してください。

## リリースエビデンス収集のスケジュール {#schedule-release-evidence-collection}

APIでは:

- 将来の`released_at`の日付を指定した場合、そのリリースは**Upcoming release**となり、エビデンスはリリース日に収集されます。それより前にリリースエビデンスを収集することはできません。
- 過去の`released_at`の日付を指定した場合、そのリリースは**過去のリリース**となり、エビデンスは収集されません。
- `released_at`の日付を指定しない場合、リリースエビデンスはリリース作成日に収集されます。
