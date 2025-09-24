---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabプロジェクトをJiraに接続して、両方のプラットフォーム全体で合理化された開発ワークフローを維持します。チームがイシュートラッキングにJiraを使用し、開発にGitLabを使用する場合、Jiraインテグレーションによって計画と実行が連携されます。

Jiraインテグレーションの利点:

- 開発チームは、頭の切り替えなしにGitLabでJiraのイシューに直接アクセスできます。
- プロジェクトマネージャーは、チームがGitLabで作業する際に、Jiraで開発の進捗状況を追跡します。
- デベロッパーがコミットとマージリクエストでJiraのイシューを参照すると、それらのイシューが自動的に更新されます。
- チームメンバーは、Jiraのイシューで追跡されているコードの変更と要件の間の関係を把握できます。
- GitLabでの脆弱性検出結果から、適切な追跡と解決のためにJiraでイシューが作成されます。

[JiraのイシューをGitLabにインポートする](../../user/project/import/jira.md)か、JiraをGitLabと統合して、両方のプラットフォームを組み合わせて使い続けることができます。

## Jiraインテグレーション {#jira-integrations}

GitLabは2種類のJiraインテグレーションを提供しています。[必要な機能に応じて](#feature-availability)、いずれかまたは両方のインテグレーションを使用できます。

### Jiraのイシューのインテグレーション {#jira-issues-integration}

{{< history >}}

- GitLab 17.6で機能名が「Jiraのイシューのインテグレーション」に[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)。

{{< /history >}}

GitLabで開発された[Jiraのイシューのインテグレーション](configure.md)は、Jira Cloud、Jira Data Center、またはJira Serverで使用できます。このインテグレーションにより、次のことができるようになります。

- GitLabでJiraのイシューを直接表示および検索する。
- GitLabのコミットとマージリクエストで、IDでJiraのイシューを参照する。
- 脆弱性のJiraのイシューを作成する。

### Jira開発パネル {#jira-development-panel}

[Jira開発パネル](development_panel.md)を使用すると、関連するブランチ、コミット、マージリクエストなど、[イシューに関するGitLabアクティビティーを表示](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)できます。Jira開発パネルを設定するには、次のようにします。

- **Jira Cloud**では、GitLabで開発および保持されている[Jira Cloudアプリ用のGitLab](connect-app.md)を使用します。
- **Jira Data CenterまたはJira Server**では、Atlassianで開発および保持されている[Jira DVCS connector](dvcs/_index.md)を使用します。

## 機能の可用性 {#feature-availability}

次の表に、JiraのイシューのインテグレーションとJira開発パネルで使用できる機能を示します。

| 機能                                                                                                                                                                                                             | Jiraのイシューのインテグレーション                                                                                                                                                                | Jira開発パネル |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------|
| GitLabのコミットまたはマージリクエストでJiraのイシューIDをメンションすると、Jiraのイシューへのリンクが作成されます。                                                                                                               | {{< icon name="check-circle" >}}可能                                                                                                                                                   | {{< icon name="dotted-circle" >}}いいえ |
| GitLabでJiraのイシューIDをメンションすると、JiraのイシューにGitLabのイシューまたはマージリクエストが表示されます。                                                                                                                      | {{< icon name="check-circle" >}}はい。GitLabのイシューまたはマージリクエストのタイトルが記載されたJiraのコメントは、GitLabにリンクされています。最初のメンションは、Jiraのイシューの**Webリンク**にも追加されます。 | {{< icon name="check-circle" >}}はい。Jiraのイシューの[開発パネル](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)に表示されます。 |
| GitLabのコミットでJiraのイシューIDをメンションすると、Jiraのイシューにコミットメッセージが表示されます。                                                                                                                            | {{< icon name="check-circle" >}}はい。コミットメッセージ全体が、Jiraのイシューにコメントとして表示されます。また、**Webリンク**にも表示されます。各メッセージは、GitLabのコミットにリンクバックします。     | {{< icon name="check-circle" >}}はい。Jiraのイシューの開発パネルに表示されます。[Jiraスマートコミット](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html)を使用すると、カスタムコメントが可能になります。 |
| GitLabブランチ名でJiraのイシューIDをメンションすると、Jiraのイシューにブランチ名が表示されます。                                                                                                                          | {{< icon name="dotted-circle" >}}いいえ                                                                                                                                                   | {{< icon name="check-circle" >}}はい。Jiraのイシューの開発パネルに表示されます。 |
| Jiraのイシューにタイムトラッキングを追加します。                                                                                                                                                                                  | {{< icon name="dotted-circle" >}}いいえ                                                                                                                                                   | {{< icon name="check-circle" >}}はい。Jiraスマートコミットを使用します。 |
| GitLabのコミットまたはマージリクエストを使用して、Jiraのイシューを移行します。                                                                                                                                                    | {{< icon name="check-circle" >}}はい。1回の移行のみです。通常、Jiraのイシューを完了するために使用されます。                                                                                | {{< icon name="check-circle" >}}はい。Jiraスマートコミットを使用して、Jiraのイシューを任意の状態に移行することができます。 |
| [Jiraのイシューのリストを表示します](configure.md#view-jira-issues)。                                                                                                                                                        | {{< icon name="check-circle" >}}可能                                                                                                                                                   | {{< icon name="dotted-circle" >}}いいえ |
| [脆弱性のJiraのイシューを作成します](configure.md#create-a-jira-issue-for-a-vulnerability)。                                                                                                                    | {{< icon name="check-circle" >}}可能                                                                                                                                                   | {{< icon name="dotted-circle" >}}いいえ |
| JiraのイシューからGitLabブランチを作成します。                                                                                                                                                                           | {{< icon name="dotted-circle" >}}いいえ                                                                                                                                                   | {{< icon name="check-circle" >}}はい。Jiraのイシューの開発パネルに表示されます。 |
| GitLabのマージリクエスト、ブランチ名、または最後に環境に正常にデプロイされた後のブランチに対する最後の2,000件のコミットのいずれかで、JiraのイシューIDをメンションして、GitLabのデプロイをJiraのイシューに同期します。 | {{< icon name="dotted-circle" >}}いいえ                                                                                                                                                   | {{< icon name="check-circle" >}}はい。Jiraのイシューの開発パネルに表示されます。 |

## プライバシーに関する考慮事項 {#privacy-considerations}

すべてのJiraのイシューのインテグレーションは、GitLabの外部でデータを共有します。非公開のGitLabプロジェクトをJiraと統合すると、Jiraプロジェクトへのアクセス権を持つユーザーと非公開データを共有することになります。

[Jiraのイシューのインテグレーション](configure.md)は、GitLabデータをJiraイシューにコメントとして投稿します。[Jira Cloudアプリ用のGitLab](connect-app.md)と[Jira DVCS connector](dvcs/_index.md)は、[Jira開発パネル](development_panel.md)を介してGitLabデータを共有します。Jira開発パネルでは、特定のユーザーグループまたはロールへのアクセスを制限できます。

## 関連トピック {#related-topics}

- [サードパーティのJiraインテグレーション](https://marketplace.atlassian.com/search?product=jira&query=gitlab)
