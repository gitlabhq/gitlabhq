---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: OKRの作成、編集、管理方法について説明します。
title: 目標と主な成果（OKR）
description: 目標設定、パフォーマンス追跡、子目標、およびヘルスステータス。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.6で`okrs_mvc`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103355)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能フラグによって、この機能の可用性が制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

[OKR](https://en.wikipedia.org/wiki/OKR)は、組織の全体的な戦略とビジョンに合致した目標を設定し、追跡するためのフレームワークです。

GitLabにおける目標と主な成果は、多くの機能を共有しています。ドキュメントでは、**OKRs**という用語は目標と主な成果の両方を指します。

OKRsは作業アイテムの一種であり、GitLabにおける[デフォルトイシュータイプ](https://gitlab.com/gitlab-org/gitlab/-/issues/323404)への第一歩です。[イシュー](project/issues/_index.md)と[エピック](group/epics/_index.md)を作業アイテムに移行し、カスタム作業アイテムタイプを追加するためのロードマップについては、[エピック6033](https://gitlab.com/groups/gitlab-org/-/epics/6033)または[Plan方向性のページ](https://about.gitlab.com/direction/plan/)を参照してください。

## 効果的なOKRsの設計 {#designing-effective-okrs}

目標と主な成果を使用して、従業員を共通の目標に合わせ、進捗状況を追跡します。目標で大きなゴールを設定し、[子目標と主な成果](#child-objectives-and-key-results)を使用して大きなゴールの達成度を測定します。

**Objectives**とは、達成すべき意欲的なゴールであり、**what you're aiming to do**を定義します。目標は、個人、チーム、部門の仕事が組織全体の方向性にどのように影響するかを、彼らの仕事を会社全体の戦略に結びつけることで示します。

**Key results**は、整合された目標に対する進捗状況の測定値です。**how you know if you have reached your goal**を表現します。特定の成果（主な成果）を達成することで、リンクされた目標の進捗が生まれます。

あなたのOKRが理にかなっているかどうかを知るには、この文章を使うことができます:

<!-- vale gitlab_base.FutureTense = NO -->
> 私/私たちは、以下のメトリクス（主な成果）を達成することで、（目標）を（日付）までに達成します。
<!-- vale gitlab_base.FutureTense = YES -->

より良いOKRsの作成方法と、GitLabでの使用方法については、[OKRハンドブックページ](https://handbook.gitlab.com/handbook/company/okrs/)を参照してください。

## 目標を作成する {#create-an-objective}

目標を作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択します。
1. 右上の**新規イシュー**の隣にある下矢印{{< icon name="chevron-lg-down" >}}を選択し、**New objective**を選択します。
1. 再度**New objective**を選択します。
1. 目標のタイトルを入力します。
1. **Create objective**を選択します。

主な成果を作成するには、既存の目標に[子として追加](#add-a-child-key-result)します。

## 目標を表示する {#view-an-objective}

目標を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択します。
1. `Type = objective`の[イシューのリストをフィルタリング](project/issues/managing_issues.md#filter-the-list-of-issues)します。
1. リストから目標のタイトルを選択します。

## 主な成果を表示する {#view-a-key-result}

主な成果を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択します。
1. `Type = key_result`の[イシューのリストをフィルタリング](project/issues/managing_issues.md#filter-the-list-of-issues)します。
1. リストから主な成果のタイトルを選択します。

または、その親の目標にある**子アイテム**セクションから主な成果にアクセスすることもできます。

## タイトルと説明を編集する {#edit-title-and-description}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

OKRを編集するには:

1. 編集したい[目標](okrs.md#view-an-objective)または[主な成果](#view-a-key-result)を開きます。
1. オプション。オプション。タイトルを編集するには、それを選択し、変更を加えて、タイトルテキストボックスの外側の任意の領域を選択します。
1. オプション。説明を編集するには、編集アイコン（{{< icon name="pencil" >}}）を選択して変更し、**保存**を選択します。

## **続きを読む**で説明が省略されるのを防ぐ {#prevent-truncating-descriptions-with-read-more}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184)されました。

{{< /history >}}

OKRの説明が長い場合、GitLabはその一部のみを表示します。説明全体を表示するには、**続きを読む**を選択する必要があります。この切り詰める機能により、長文をスクロールせずに、ページ上の他の要素を簡単に見つけることができます。

説明を切り詰めるかどうかを変更するには:

1. 目標または主な成果の右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **表示オプション**を選択します。
1. 好みに応じて**説明を折りたたむ**を切り替えます。

この設定は記憶され、すべてのイシュー、タスク、エピック、目標、および主な成果に影響します。

## 右側のサイドバーを非表示にする {#hide-the-right-sidebar}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184)されました。

{{< /history >}}

属性は、スペースが許す限り、説明の右側のサイドバーに表示されます。サイドバーを非表示にして、説明のスペースを増やすには: 

1. 目標または主な成果の右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **表示オプション**を選択します。
1. **サイドバーを非表示にする**を選択します。

この設定は記憶され、すべてのイシュー、タスク、エピック、目標、および主な成果に影響します。

サイドバーを再度表示するには: 

- 上記の手順を繰り返し、**サイドバーを表示する**を選択します。

## OKRシステムノートを表示する {#view-okr-system-notes}

{{< history >}}

- GitLab 15.7で`work_items_mvc_2`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)されました。デフォルトでは無効になっています。
- GitLab 15.8で、`work_items_mvc`という機能フラグに[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)しました。デフォルトでは無効になっています。
- 機能フラグは[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144141)され、GitLab 16.10で`work_items_mvc`から`work_items_beta`になりました。
- GitLab 15.8で、アクティビティのソート順の変更が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)されました。
- GitLab 15.10で、アクティビティのフィルタリングが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/389971)されました。
- GitLab 15.10で[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/334812)。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。
- 機能フラグ`work_items_beta`は、GitLab 18.6で[削除](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17549)されました。

{{< /history >}}

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

OKRに関連するすべての[システムノート](project/system_notes.md)を表示できます。デフォルトでは、**古い順**にソートされます。ソート順はいつでも**新しい順**に変更でき、この設定はセッション間で保持されます。

## コメントとスレッド {#comments-and-threads}

OKRs内で[コメント](discussions/_index.md)を追加し、スレッドに返信することができます。

## ユーザーを割り当てる {#assign-users}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

OKRの担当者を示すために、ユーザーを割り当てることができます。

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

OKRのアサイン担当者を変更するには:

1. 編集したい[目標](okrs.md#view-an-objective)または[主な成果](#view-a-key-result)を開きます。
1. **担当者**の横にある**担当者を追加**を選択します。
1. ドロップダウンリストから、担当者として追加するユーザーを選択します。
1. ドロップダウンリストの外側の領域を選択します。

## ラベルを割り当てる {#assign-labels}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

[ラベル](project/labels.md)を使用して、チーム間でOKRsを整理します。

OKRにラベルを追加するには:

1. 編集したい[目標](okrs.md#view-an-objective)または[主な成果](#view-a-key-result)を開きます。
1. **ラベル**の横にある**ラベルを追加**を選択します。
1. ドロップダウンリストから、追加するラベルを選択します。
1. ドロップダウンリストの外側の領域を選択します。

## マイルストーンに目標を追加する {#add-an-objective-to-a-milestone}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/367463)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

[マイルストーン](project/milestones/_index.md)に目標を追加できます。目標を表示する際に、マイルストーンのタイトルを確認できます。

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

マイルストーンに目標を追加するには:

1. 編集したい[目標](okrs.md#view-an-objective)を開きます。
1. **マイルストーン**の横にある**マイルストーンに追加**を選択します。目標がすでにマイルストーンに属している場合、ドロップダウンリストに現在のマイルストーンが表示されます。
1. ドロップダウンリストから、目標に関連付けるマイルストーンを選択します。

## 進捗を設定する {#set-progress}

{{< history >}}

- GitLab 15.8で[主な成果の進捗設定](https://gitlab.com/gitlab-org/gitlab/-/issues/382433)が導入されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

目標達成に必要な作業のうち、どれだけ完了したかを示します。

目標と主な成果で手動で進捗を設定できます。

子アイテムの進捗を入力すると、階層内のすべての親アイテムの進捗が子アイテムの進捗の平均に更新されます。任意のレベルで進捗をオーバーライドして手動で値を入力できますが、子アイテムの進捗値が更新されると、自動化によってすべての親が平均を表示するように再度更新されます。

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

目標または主な成果の進捗を設定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択します。
1. `Type = objective`または`Type = key result`で[イシューのリストをフィルタリング](project/issues/managing_issues.md#filter-the-list-of-issues)し、アイテムを選択します。
1. **進行状況**の隣にあるテキストボックスを選択します。
1. 0から100までの数字を入力します。

## ヘルスステータスを設定する {#set-health-status}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381899)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

目標達成のリスクをよりよく追跡するために、各目標と主な成果に[ヘルスステータス](project/issues/managing_issues.md#health-status)を割り当てることができます。ヘルスステータスを使用すると、OKRsが計画通りに進んでいるか、またはスケジュール通りに進めるために注意が必要であるかを組織内の他の人に知らせることができます。

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

OKRのヘルスステータスを設定するには:

1. 編集したい[主な成果を開きます](okrs.md#view-a-key-result)。
1. **ヘルスステータス**の隣にあるドロップダウンリストを選択し、希望のヘルスステータスを選択します。

## 主な成果を目標にプロモートする {#promote-a-key-result-to-an-objective}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386877)されました。
- GitLab 16.1でクイックアクション`/promote_to`が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/412534)。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

主な成果をプロモートするには:

1. [主な成果を開きます](#view-a-key-result)。
1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **目標にプロモート**を選択します。

または、[`/promote_to objective`クイックアクション](project/quick_actions.md#promote_to)を使用します。

## OKRを別のアイテムタイプに変換する {#convert-an-okr-to-another-item-type}

{{< history >}}

- GitLab 17.8で`work_items_beta`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385131)されました。デフォルトでは無効になっています。
- `okrs_mvc`という[フラグ](../administration/feature_flags/_index.md)に[移動しました](https://gitlab.com/gitlab-org/gitlab/-/issues/385131)。現在のフラグの状態については、このページの上部を参照してください。

{{< /history >}}

目標または主な成果を、次のような別のアイテムタイプに変換します:

- イシュー
- タスク
- 目標
- 主な成果

> [!warning]
> ターゲットタイプが元のタイプのすべてのフィールドをサポートしていない場合、タイプの変更によりデータが失われる可能性があります。

前提条件: 

- 変換したいOKRには、親アイテムが割り当てられていてはいけません。
- 変換したいOKRには、子アイテムがあってはいけません。

OKRを別のアイテムタイプに変換するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択し、表示するイシューを選択します。
1. イシューリストで、目標または主な成果を見つけて選択します。
1. 右上隅で、**その他のアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**種類の変更**を選択します。
1. 目的のアイテムタイプを選択します。
1. すべての条件が満たされたら、**種類の変更**を選択します。

または、コメントで[`/type`クイックアクション](project/quick_actions.md#type)に続けて`issue`、`task`、`objective`、または`key result`を使用できます。

## 目標または主な成果の参照をコピーする {#copy-objective-or-key-result-reference}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396553)されました。

{{< /history >}}

GitLabの他の場所で目標または主な成果を参照するには、完全なURLまたは短縮参照を使用できます。短縮参照は`namespace/project-name#123`のようになります。`namespace`はグループまたはユーザー名のいずれかです。

目標または主な成果の参照をクリップボードにコピーするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択し、目標または主な成果を選択して表示します。
1. 右上隅の縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、次に**参照をコピー**を選択します。

これで、この参照を別の説明またはコメントに貼り付けることができます。

目標または主な成果の参照については、[GitLab Flavored Markdown](markdown.md#gitlab-specific-references)で詳細を確認してください。

## 目標または主な成果のメールアドレスをコピーする {#copy-objective-or-key-result-email-address}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396553)されました。

{{< /history >}}

メールを送信することで、目標または主な成果にコメントを作成できます。このアドレスにメールを送信すると、メール本文を含むコメントが作成されます。

メールの送信によるコメントの作成、および必要な設定の詳細については、[メールを送信してコメントに返信する](discussions/_index.md#reply-to-a-comment-by-sending-email)を参照してください。

目標または主な成果のメールアドレスをコピーするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択し、表示するイシューを選択します。
1. 右上隅の縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、次に**Copy objective email address**または**Copy key result email address**を選択します。

## OKRをクローズする {#close-an-okr}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

OKRが達成されたら、それをクローズできます。OKRはクローズ済みとしてマークされますが、削除はされません。

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

OKRをクローズするには:

1. 編集したい[目標](okrs.md#view-an-objective)を開きます。
1. **ステータス**の隣にある**クローズ**を選択します。

同じ方法で、クローズされたOKRを再度開くことができます。

## 子目標と主な成果 {#child-objectives-and-key-results}

GitLabでは、目標は主な成果と似ています。あなたのワークフローでは、目標で説明されているゴールを測定するために主な成果を使用します。

子目標は合計9レベルまで追加できます。目標は最大100個の子OKRsを持つことができます。主な成果は目標の子であり、それ自体が子アイテムを持つことはできません。

子目標と主な成果は、目標の説明の下にある**子アイテム**セクションで利用できます。

### 子目標を追加する {#add-a-child-objective}

{{< history >}}

- 目標を作成するプロジェクトを選択する機能は、GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/436255)。

{{< /history >}}

前提条件: 

- プロジェクトに対するゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

目標に新しい目標を追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、次に**New objective**を選択します。
1. 新しい目標のタイトルを入力します。
1. 新しい目標を作成する[プロジェクト](project/organize_work_with_projects.md)を選択します。
1. **Create objective**を選択します。

既存の目標に目標を追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、次に**Existing objective**を選択します。
1. 目的の目標のタイトルの一部を入力して検索し、目的の項目を選択します。

   複数の目標を追加するには、この手順を繰り返します。
1. **Add objective**を選択します。

### 子主な成果を追加する {#add-a-child-key-result}

{{< history >}}

- 主な成果を作成するプロジェクトを選択する機能は、GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/436255)。

{{< /history >}}

前提条件: 

- プロジェクトに対するゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

目標に新しい主な成果を追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、次に**New key result**を選択します。
1. 新しい主な成果のタイトルを入力します。
1. 新しい主な成果を作成する[プロジェクト](project/organize_work_with_projects.md)を選択します。
1. **Create key result**を選択します。

既存の主な成果を目標に追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、次に**Existing key result**を選択します。
1. 目的のOKRのタイトルの一部を入力して検索し、目的の項目を選択します。

   複数の目標を追加するには、この手順を繰り返します。
1. **Add key result**を選択します。

### 目標と主な成果の子を並べ替える {#reorder-objective-and-key-result-children}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385887)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

デフォルトでは、子OKRsは作成日によって順序付けられます。並べ替えるには、ドラッグして移動します。

### OKRのチェックインリマインダーをスケジュールする {#schedule-okr-check-in-reminders}

{{< history >}}

- GitLab 16.4で`okr_checkin_reminders`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422761)されました。デフォルトでは無効になっています。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

> [!flag]
> この機能フラグによって、この機能の可用性が制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

チェックインリマインダーをスケジュールして、チームに主な成果のステータス更新を提供するよう促します。リマインダーは、子孫オブジェクトと主な成果のすべての割り当て担当者にメール通知およびTo-Doアイテムとして送信されます。ユーザーはメール通知の購読を解除できませんが、チェックインリマインダーはオフにできます。リマインダーは毎週火曜日に送信されます。

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。
- プロジェクトには、少なくとも1つの主な成果を持つ少なくとも1つの目標が必要です。
- リマインダーは最上位の目標に対してのみスケジュールできます。子目標のチェックインリマインダーをスケジュールしても効果はありません。最上位の目標の設定は、すべての子目標に継承されます。

目標のリマインダーを定期的にスケジュールするには、新しいコメントで[`/checkin_reminder`クイックアクション](project/quick_actions.md#checkin_reminder)を使用します。

## 目標を親として設定する {#set-an-objective-as-a-parent}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11198)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。
- 親目標と子OKRは同じプロジェクトに属している必要があります。

目標をOKRの親として設定するには:

1. 編集したい[目標](#view-an-objective)または[主な成果](#view-a-key-result)を開きます。
1. **親**の横にあるドロップダウンから、追加する親を選択します。
1. ドロップダウンリストの外側の領域を選択します。

目標または主な成果の親を削除するには、**親**の隣にあるドロップダウンリストを選択し、次に**アサイン解除**を選択します。

## 機密OKRs {#confidential-okrs}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8410)されました。

{{< /history >}}

機密OKRsは、[十分な権限](#who-can-see-confidential-okrs)を持つプロジェクトのメンバーにのみ表示されるOKRsです。機密OKRsを使用して、セキュリティの脆弱性を非公開にしたり、予期せぬ情報の漏洩を防ぐことができます。

### OKRを機密にする {#make-an-okr-confidential}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

デフォルトでは、OKRsは公開です。OKRは、作成時または編集時に機密に設定できます。

#### 新しいOKRで {#in-a-new-okr}

新しい目標を作成すると、テキストエリアのすぐ下に、OKRを機密としてマークするためのチェックボックスが表示されます。

そのチェックボックスを選択し、次に**Create objective**または**Create key result**を選択してOKRを作成します。

#### 既存のOKRで {#in-an-existing-okr}

前提条件: 

- プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。
- **confidential objective**は、機密[子目標または主な成果](#child-objectives-and-key-results)のみを持つことができます:
  - 目標を機密にするには: 子目標または主な成果がある場合、まずそれらすべてを機密にするか、削除する必要があります。
  - 目標を非機密にするには: 子目標または主な成果がある場合、まずそれらすべてを非機密にするか、削除する必要があります。
  - 機密目標に子目標または主な成果を追加するには、まずそれらを機密にする必要があります。

既存のOKRの機密性を変更するには:

1. [目標](#view-an-objective)または[主な成果](#view-a-key-result)を開きます。
1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **非公開に設定**または**公開に設定する**を選択します。

### 機密OKRsを閲覧できる人 {#who-can-see-confidential-okrs}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

OKRが機密になると、プロジェクトに対するプランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持つユーザーのみがOKRにアクセスできます。ゲストまたは[Minimal](permissions.md#users-with-minimal-access)ロールを持つユーザーは、変更前に積極的に参加していたとしてもOKRにアクセスできません。

ただし、**Guest role**を持つユーザーは機密OKRsを作成できますが、自分が作成したOKRsのみを表示できます。

ゲストユーザーまたは非メンバーは、OKRに割り当てられている場合、機密OKRを読み取りできます。ゲストユーザーまたは非メンバーが機密OKRから割り当て解除されると、そのOKRは表示できなくなります。

機密OKRsは、必要な権限を持たないユーザーの検索結果には表示されません。

### 機密OKRインジケーター {#confidential-okr-indicators}

機密OKRsは、いくつかの点で通常のOKRsとは視覚的に異なります。OKRsがリストされている場所であればどこでも、機密としてマークされているOKRsの隣に機密（{{< icon name="eye-slash" >}}）アイコンが表示されます。

[十分な権限](#who-can-see-confidential-okrs)がない場合、機密OKRsをまったく表示できません。

同様に、OKR内では、パンくずリストのすぐ隣に機密（{{< icon name="eye-slash" >}}）アイコンが表示されます。

通常から機密への変更、およびその逆の変更はすべて、OKRのコメントにあるシステムノートによって示されます。例:

- {{< icon name="eye-slash" >}} Jo Garciaが5分前にイシューを非公開にしました
- {{< icon name="eye" >}} Jo Garciaがたった今、イシューを全員に公開しました

## ディスカッションをロックする {#lock-discussion}

{{< history >}}

- GitLab 16.9で`work_items_beta`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/398649)されました。デフォルトでは無効になっています。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

> [!flag]
> この機能フラグによって、この機能の可用性が制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

OKRでの公開コメントを禁止できます。その場合、プロジェクトメンバーのみがコメントを追加および編集できます。

前提条件: 

- プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

OKRをロックするには:

1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **ディスカッションのロック**を選択します。

システムノートがページの詳細に追加されます。

OKRがロックされたディスカッションでクローズされている場合、ディスカッションがロック解除されるまで再度開くことはできません。

## OKR内のリンクされたアイテム {#linked-items-in-okrs}

{{< history >}}

- GitLab 16.5で`linked_work_items`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416558)されました。デフォルトでは有効になっています。
- GitLab 16.7の[GitLab.comおよびGitLab Self-Managedで有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139394)されました。
- GitLab 16.8で、URLとIDを入力して関連アイテムを追加する機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/427594)されました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150148)になりました。機能フラグ`linked_work_items`は削除されました。
- GitLab 17.0で、必要な最小ロールがレポーター（trueの場合）からゲストに[変更](https://gitlab.com/groups/gitlab-org/-/epics/10267)されました。

{{< /history >}}

リンクされたアイテムは双方向の関係であり、子目標と主な成果の下のブロックに表示されます。同じプロジェクト内の目標、主な成果、またはタスクを相互にリンクできます。

この関係は、ユーザーが両方のアイテムを表示できる場合にのみUIに表示されます。

### リンクされたアイテムを追加する {#add-a-linked-item}

前提条件: 

- プロジェクトに対するゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

アイテムを目標または主な成果にリンクするには:

1. 目標または主な成果の**リンクされたアイテム**セクションで、**追加**を選択します。
1. 2つのアイテム間の関係を次のいずれかの操作を行います:
   - **以下に関係する**
   - **ブロック**
   - **は次の人によってブロックされています:**
1. アイテムの検索テキスト、URL、または参照IDを入力します。
1. リンクするアイテムをすべて追加したら、検索ボックスの下にある**追加**を選択します。

リンクされたすべてのアイテムの追加が完了すると、それらの関係が視覚的にわかりやすく分類されて表示されます。

![Linked work items categorized as blocking, blocked by, or related to, with status indicators to visualize progress, and dependencies.](img/linked_items_list_v16_5.png)

### リンクされたアイテムを削除する {#remove-a-linked-item}

前提条件: 

- プロジェクトに対するゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

目標または主な成果の**リンクされたアイテム**セクションで、各アイテムの隣にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、次に**削除**を選択します。

双方向の関係性により、いずれのアイテムにも関係が表示されなくなります。
