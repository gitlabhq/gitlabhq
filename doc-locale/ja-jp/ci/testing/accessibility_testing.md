---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アクセシビリティテスト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

アプリケーションがウェブインターフェースを提供する場合、[GitLab CI/CD](../_index.md)を使用して、保留中のコード変更によるアクセシビリティへの影響を判断できます。

[Pa11y](https://pa11y.org/)は、ウェブサイトのアクセシビリティを測定するためのFreeのオープンソースツールです。GitLabはPa11yを[CI/CDジョブテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml)に統合します。`a11y`ジョブは、定義された一連のウェブページを分析し、アクセシビリティの違反、警告、通知を`accessibility`という名前のファイルでレポートします。

Pa11yは[WCAG 2.1ルール](https://www.w3.org/TR/WCAG21/#new-features-in-wcag-2-1)を使用します。

## アクセシビリティマージリクエストウィジェット {#accessibility-merge-request-widget}

GitLabは、マージリクエストウィジェット領域に**Accessibility Report**を表示します:

![Accessibilityマージリクエストウィジェット](img/accessibility_mr_widget_v13_0.png)

## アクセシビリティテストの設定 {#configure-accessibility-testing}

GitLab CI/CDでPa11yを実行するには、[GitLab Accessibility Dockerイメージ](https://gitlab.com/gitlab-org/ci-cd/accessibility)を使用します。

`a11y`ジョブを定義するには:

1. お使いのGitLabインストールから、[`Accessibility.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml)を[含めて](../yaml/_index.md#includetemplate)ください。
1. 次の設定を`.gitlab-ci.yml`ファイルに追加します。

   ```yaml
   stages:
     - accessibility

   variables:
     a11y_urls: "https://about.gitlab.com https://gitlab.com/users/sign_in"

   include:
     - template: "Verify/Accessibility.gitlab-ci.yml"
   ```

1. Pa11yでテストするウェブページのURLをリストするために、`a11y_urls`変数をカスタマイズします。

CI/CDパイプライン内の`a11y`ジョブは、次のファイルを生成します:

- `a11y_urls`変数にリストされているURLごとに1つのHTMLレポート。
- 収集されたレポートデータを含む1つのファイル。このファイルは`gl-accessibility.json`という名前です。

ブラウザで[ジョブアーティファクトを表示](../jobs/job_artifacts.md#download-job-artifacts)できます。

> [!note]
> テンプレートによって提供されるジョブ定義は、Kubernetesをサポートしていません。

CIの設定を介してPa11yに設定を渡すことはできません。設定を変更するには、CIファイル内のテンプレートのコピーを編集します。
