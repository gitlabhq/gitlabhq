---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 目標と主な成果（OKR）を作成、編集、および管理する方法について説明します。
title: 目標と主な成果（OKR）
description: 目標設定、パフォーマンスの追跡、子目標、ヘルスステータス。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.6で`okrs_mvc`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103355)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

[目標と主な成果](https://en.wikipedia.org/wiki/OKR)（OKR）は、組織全体の戦略とビジョンに合わせて目標を設定および追跡するためのフレームワークです。

GitLabの目標と主な成果は、多くの機能を共有しています。ドキュメントでは、**OKRs**（OKR）という用語は、目標と主な成果の両方を指します。

OKRは作業アイテムの一種であり、GitLabの[デフォルトのイシュータイプ](https://gitlab.com/gitlab-org/gitlab/-/issues/323404)へ向けたステップです。[イシュー](project/issues/_index.md)と[エピック](group/epics/_index.md)を作業アイテムに移行し、カスタム作業アイテムタイプを追加するロードマップについては、[エピック6033](https://gitlab.com/groups/gitlab-org/-/epics/6033)または[方向性のページ](https://about.gitlab.com/direction/plan/)を参照してください。

## 効果的なOKRの設計 {#designing-effective-okrs}

目標と主な成果を使用して、従業員を共通の目標に向けて連携させ、進行状況を追跡するします。目標で大きな目標を設定し、[子目標と主な成果](#child-objectives-and-key-results)を使用して、大きな目標の完了を測定します。

**目的**は、達成すべき意欲的な目標であり、**what you're aiming to do**（何を目指しているのか）を定義します。個々の従業員、チーム、または部門の仕事が、組織全体の戦略に仕事を結び付けることによって、組織の全体的な方向にどのように影響するかを示します。

**主な結果**は、連携された目標に対する進行状況の測定です。**how you know if you have reached your goal**（目標）を表します。特定の成果（主な成果）を達成することにより、リンクされた目標に進行状況が生まれます。

OKRが理にかなっているかどうかを知るために、次の文を使用できます:

<!-- vale gitlab_base.FutureTense = NO -->
> 私/私たちは、次のメトリクス（主な成果）を達成することにより、（日付）までに（目標）を達成します。
<!-- vale gitlab_base.FutureTense = YES -->

より良いOKRを作成する方法と、GitLabでOKRをどのように使用するかについては、[目標と主な成果のハンドブックページ](https://handbook.gitlab.com/handbook/company/okrs/)を参照してください。

## 目標の作成 {#create-an-objective}

目標を作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. 右上隅の**新規イシュー**の横にある下向き矢印{{< icon name="chevron-lg-down" >}}を選択し、**New objective**（新規目標）を選択します。
1. **New objective**（新規目標）を再度選択します。
1. 目標タイトルを入力します。
1. **Create objective**（目標の作成）を選択します。

主な成果を作成するには、既存の目標に[子として追加](#add-a-child-key-result)します。

## 目標の表示 {#view-an-objective}

目標を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. [イシューのリストをフィルター](project/issues/managing_issues.md#filter-the-list-of-issues)する`Type = objective`。
1. リストから目標のタイトルを選択します。

## 主な成果の表示 {#view-a-key-result}

主な成果を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. [イシューのリストをフィルター](project/issues/managing_issues.md#filter-the-list-of-issues)する`Type = key_result`。
1. リストから主な成果のタイトルを選択します。

または、親の目標の**子アイテム**セクションから主な成果にアクセスできます。

## タイトルと説明を編集 {#edit-title-and-description}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。

OKRを編集するには:

1. 編集する[目標を開く](okrs.md#view-an-objective)か、[主な成果](#view-a-key-result)を開きます。
1. オプション。タイトルを編集するには、タイトルを選択し、変更を加え、タイトルのテキストボックスの外側の領域を選択します。
1. オプション。説明を編集するには、編集アイコン（{{< icon name="pencil" >}}）を選択して変更し、**保存**を選択します。

## 「**続きを読む**」で説明が省略されるのを防ぎます。 {#prevent-truncating-descriptions-with-read-more}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184)されました。

{{< /history >}}

OKRの説明が長い場合、GitLabはその一部のみを表示します。説明全体を表示するには、**続きを読む**を選択する必要があります。この切り詰める機能により、長文をスクロールせずに、ページ上の他の要素を簡単に見つけることができます。

説明を切り詰めるかどうかを変更するには:

1. 目標または主な成果で、右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **表示オプション**を選択します()。
1. 好みに応じて**説明を折りたたむ**を切り替えます。

この設定は記憶され、すべてのイシュー、タスク、エピック、目標、および主な成果に影響します。

## 右側のサイドバーを非表示にする {#hide-the-right-sidebar}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184)されました。

{{< /history >}}

属性は、スペースがある場合、説明の右側のサイドバーに表示されます。サイドバーを非表示にして、説明のスペースを増やすには: 

1. 目標または主な成果で、右上隅にある**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **表示オプション**を選択します()。
1. **サイドバーを非表示にする**を選択します。

この設定は記憶され、すべてのイシュー、タスク、エピック、目標、および主な成果に影響します。

サイドバーを再度表示するには: 

- 上記の手順を繰り返し、**サイドバーを表示する**を選択します。

## OKRシステムノートの表示 {#view-okr-system-notes}

{{< history >}}

- GitLab 15.7で`work_items_mvc_2`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)されました。デフォルトでは無効になっています。
- GitLab 15.8で、`work_items_mvc`という機能フラグに[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)しました。デフォルトでは無効になっています。
- 機能フラグは、GitLab 16.10で`work_items_mvc`から`work_items_beta`[に変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144141)されました。
- GitLab 15.8で、アクティビティーのソート順の変更が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378949)されました。
- GitLab 15.10で、アクティビティーのフィルタリングが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/389971)されました。
- GitLab 15.10の[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/334812)。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。

OKRに関連するすべての[システムノート](project/system_notes.md)を表示できます。デフォルトでは、**古い順**にソートされます。ソート順はいつでも**新しい順**に変更でき、この設定はセッション間で保持されます。

## コメントとスレッド {#comments-and-threads}

OKRに[コメント](discussions/_index.md)を追加したり、スレッドに返信したりできます。

## ユーザーを割り当てる {#assign-users}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

OKRの担当者を表示するには、OKRにユーザーを割り当てます。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

OKRのアサイン先を変更するには:

1. 編集する[目標を開く](okrs.md#view-an-objective)か、[主な成果](#view-a-key-result)を開きます。
1. **担当者**の横にある**Add assignees**（担当者を追加）を選択します。
1. ドロップダウンリストから、担当者として追加するユーザーを選択します。
1. ドロップダウンリストの外側の領域を選択します。

## ラベルの割り当て {#assign-labels}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。

[ラベル](project/labels.md)を使用して、チーム間でOKRを編成します。

OKRにラベルを追加するには、次の手順に従います:

1. 編集する[目標を開く](okrs.md#view-an-objective)か、[主な成果](#view-a-key-result)を開きます。
1. **ラベル**の横にある**ラベルを追加**を選択します。
1. ドロップダウンリストから、追加するラベルを選択します。
1. ドロップダウンリストの外側の領域を選択します。

## マイルストーンへの目標の追加 {#add-an-objective-to-a-milestone}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/367463)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

[マイルストーン](project/milestones/_index.md)に目標を追加できます。目標を表示すると、マイルストーンのタイトルを確認できます。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

マイルストーンに目標を追加するには:

1. 編集する[目標を開く](okrs.md#view-an-objective)。
1. **マイルストーン**の横にある**Add to milestone**（マイルストーンに追加）を選択します。目標がすでにマイルストーンに属している場合、ドロップダウンリストに現在のマイルストーンが表示されます。
1. ドロップダウンリストから、目標に関連付けるマイルストーンを選択します。

## 進行状況の設定 {#set-progress}

{{< history >}}

- 主な成果の進行状況の設定は、GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/382433)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

目標の達成に必要な作業のどの程度が完了したかを示します。

目標と主な成果に手動で進行状況を設定できます。

子アイテムの進行状況を入力すると、階層内のすべての親アイテムの進行状況が、子アイテムの進行状況の平均に更新されます。任意のレベルで進行状況をオーバーライドして手動で値を入力できますが、子アイテムの進行状況の値が更新されると、自動化によりすべての親が再度更新され、平均が表示されます。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

目標または主な成果の進行状況を設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. `Type = objective`または`Type = key result`の[イシューリストをフィルタリング](project/issues/managing_issues.md#filter-the-list-of-issues)し、アイテムを選択します。
1. **進行状況**の横にあるテキストボックスを選択します。
1. 0から100までの数値を入力します。

## ヘルスステータスを設定 {#set-health-status}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381899)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

目標達成のリスクをより適切に追跡するために、各目標と主な成果に[ヘルスステータス](project/issues/managing_issues.md#health-status)を割り当てることができます。ヘルスステータスを使用すると、計画どおりにOKRが進捗しているか、スケジュールどおりに進捗するために注意が必要かを組織内の他の人に知らせることができます。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

OKRのヘルスステータスを設定するには:

1. 編集する[主な成果を開きます](okrs.md#view-a-key-result)。
1. **ヘルスステータス**の横にあるドロップダウンリストを選択し、目的のヘルスステータスを選択します。

## 主な成果を目標にプロモート {#promote-a-key-result-to-an-objective}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386877)されました。
- クイックアクション`/promote_to`はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412534)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。

主な成果をプロモートするには:

1. [主な成果を開きます](#view-a-key-result)。
1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **目標にプロモート**を選択します。

または、`/promote_to objective`[クイックアクション](project/quick_actions.md)を使用します。

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

{{< alert type="warning" >}}

ターゲットのタイプが元のタイプのすべてのフィールドをサポートしていない場合、タイプを変更するとデータが失われる可能性があります。

{{< /alert >}}

前提要件: 

- 変換するOKRには、親アイテムが割り当てられていない必要があります。
- 変換するOKRに子アイテムが割り当てられていないことを確認してください。

OKRを別のアイテムタイプに変換するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択し、イシューを選択して表示します。
1. イシューリストで、目標または主な成果を見つけて選択します。
1. 右上隅で、**追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**種類の変更**を選択します。
1. 目的のアイテムタイプを選択します。
1. すべての条件が満たされたら、**種類の変更**を選択します。

または、`/type`[クイックアクション](project/quick_actions.md#work-items)を使用し、コメントで`issue`、`task`、`objective`または`key result`を追加することもできます。

## 目標または主な成果の参照のコピー {#copy-objective-or-key-result-reference}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396553)されました。

{{< /history >}}

GitLabの別の場所で目標または主な成果を参照するには、完全なURLまたは短い参照（`namespace/project-name#123`のようなもの。ここで、`namespace`はグループまたはユーザー名のいずれかです）を使用できます。

目標または主な成果の参照をクリップボードにコピーするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択し、表示する目標または主な成果を選択します。
1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**Copy Reference**（参照をコピー）を選択します。

これで、この参照を別の説明またはコメントに貼り付けることができます。

目標または主な成果の参照の詳細については、[GitLab-Flavored Markdown](markdown.md#gitlab-specific-references)を参照してください。

## 目標または主な成果のメールアドレスのコピー {#copy-objective-or-key-result-email-address}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396553)されました。

{{< /history >}}

メールを送信して、目標または主な成果にコメントを作成できます。このアドレスにメールを送信すると、メール本文を含むコメントが作成されます。

メールの送信によるコメントの作成、および必要な設定の詳細については、[メールを送信してコメントに返信する](discussions/_index.md#reply-to-a-comment-by-sending-email)を参照してください。

目標または主な成果のメールアドレスをコピーするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択し、イシューを選択して表示します。
1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**Copy objective email address**（目標メールアドレスのコピー）または**Copy key result email address**（主な成果メールアドレスのコピー）を選択します。

## OKRをクローズする {#close-an-okr}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

OKRが達成されたら、クローズできます。OKRはクローズとしてマークされますが、削除されません。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

OKRをクローズするには:

1. 編集する[目標を開きます](okrs.md#view-an-objective)。
1. **ステータス**の横にある**クローズ**を選択します。

クローズされたOKRを同じ方法で再度開くことができます。

## 子目標と主な成果 {#child-objectives-and-key-results}

GitLabでは、目標は主な成果に似ています。ワークフローでは、主な成果を使用して、目標で説明されている目標を測定します。

子アイテムの目標を合計9つのレベルに追加できます。1つの目標に、最大100個の子アイテムOKRを含めることができます。主な成果は目標の子アイテムであり、子アイテム自体を持つことはできません。

子アイテムの目標と主な成果は、目標の説明の下にある**子アイテム**セクションで使用できます。

### 子アイテム目標の追加 {#add-a-child-objective}

{{< history >}}

- 目標を作成するプロジェクトを選択する機能がGitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436255)されました。

{{< /history >}}

前提要件:

- プロジェクトのゲストロール以上が必要です。

新しい目標を目標に追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、**New objective**（新規目標）を選択します。
1. 新しい目標のタイトルを入力します。
1. 新しい目標を作成する[プロジェクト](project/organize_work_with_projects.md)を選択します。
1. **Create objective**（目標の作成）を選択します。

既存の目標を目標に追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、**Existing objective**（既存の目標）を選択します。
1. タイトルの一部を入力して、目的の一致を選択し、目的の目標を検索します。

   複数の目標を追加するには、この手順を繰り返します。
1. **Add objective**（目標の追加）を選択します。

### 子アイテム主な成果の追加 {#add-a-child-key-result}

{{< history >}}

- 主な成果を作成するプロジェクトを選択する機能がGitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436255)されました。

{{< /history >}}

前提要件:

- プロジェクトのゲストロール以上が必要です。

新しい主な成果を目標に追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、**New key result**（新規主な成果）を選択します。
1. 新しい主な成果のタイトルを入力します。
1. 新しい主な成果を作成する[プロジェクト](project/organize_work_with_projects.md)を選択します。
1. **Create key result**（主な成果の作成）を選択します。

既存の主な成果を目標に追加するには:

1. 目標の**子アイテム**セクションで、**追加**を選択し、**Existing key result**（既存の主な成果）を選択します。
1. タイトルの一部を入力して、一致する目的の項目を選択し、目的のエピックを検索します。

   複数の目標を追加するには、この手順を繰り返します。
1. **Add key result**（主な成果の追加）を選択します。

### 目標と主な成果の子アイテムの並べ替え {#reorder-objective-and-key-result-children}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385887)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。

デフォルトでは、子アイテムOKRは作成日順に並べられます。並べ替えるには、ドラッグして移動します。

### OKRチェックインリマインダーのスケジュール {#schedule-okr-check-in-reminders}

{{< history >}}

- GitLab 16.4で`okr_checkin_reminders`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422761)されました。デフォルトでは無効になっています。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

チェックインリマインダーをスケジュールして、チームに、関心のある主な成果のステータス更新を提供するように促します。リマインダーは、子孫オブジェクトと主な成果のすべてのアサイン先に、メール通知およびTo Doアイテムとして送信されます。メール通知のサブスクライブを解除することはできませんが、チェックインリマインダーはオフにすることができます。リマインダーは火曜日に送信されます。

前提要件: 

- プロジェクトのプランナーロール以上が必要です。
- プロジェクトに少なくとも1つの主な成果を持つ目標が少なくとも1つ存在する必要があります。
- 最上位の目標に対してのみリマインダーをスケジュールできます。子アイテム目標のチェックインリマインダーをスケジュールしても効果はありません。最上位の目標からの設定は、すべての子アイテム目標に継承されます。

目標の定期的なリマインダーをスケジュールするには、新しいコメントで`/checkin_reminder <cadence>`[クイックアクション](project/quick_actions.md#work-items)を使用します。`<cadence>`のオプションは以下のとおりです:

- `weekly`
- `twice-monthly`
- `monthly`
- `never`（デフォルト）

たとえば、毎週のチェックインリマインダーをスケジュールするには、次のように入力します:

```plaintext
/checkin_reminder weekly
```

チェックインリマインダーをオフにするには、次のように入力します:

```plaintext
/checkin_reminder never
```

## 目標を親として設定する {#set-an-objective-as-a-parent}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11198)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プロジェクトのプランナーロール以上が必要です。
- 親の目標と子アイテムOKRは、同じプロジェクトに属している必要があります。

OKRの親として目標を設定するには:

1. 編集する[目標を開く](#view-an-objective)か、[主な成果](#view-a-key-result)を開きます。
1. **親**の横にあるドロップダウンから、追加する親を選択します。
1. ドロップダウンリストの外側の領域を選択します。

目標または主な成果の親を削除するには、**親**の横にあるドロップダウンリストを選択し、**アサイン解除**を選択します。

## 機密OKR {#confidential-okrs}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8410)されました。

{{< /history >}}

非公開OKRは、[十分な権限](#who-can-see-confidential-okrs)を持つプロジェクトのメンバーのみが表示できるOKRです。非公開OKRを使用すると、セキュリティの脆弱性を非公開に設定することや、予期せぬ情報漏洩を防ぐことができます。

### OKRを機密にする {#make-an-okr-confidential}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

デフォルトでは、OKRは公開されています。OKRの作成時または編集時に、OKRを非公開に設定することができます。

#### 新しいOKR {#in-a-new-okr}

新しい目標を作成する際、テキストエリアのすぐ下に、OKRを非公開としてマークするためのチェックボックスが表示されます。

そのチェックボックスをオンにして、**Create objective**（目標の作成）または**Create key result**（主な成果の作成）を選択して、OKRを作成します。

#### 既存のOKRの場合 {#in-an-existing-okr}

前提要件: 

- プロジェクトのプランナーロール以上が必要です。
- **confidential objective**（機密目標）は、機密の[子アイテム目標または主な成果](#child-objectives-and-key-results)のみを持つことができます:
  - 目標を機密にするには: 子アイテム目標または主な成果がある場合は、まずすべてを機密にするか、削除する必要があります。
  - 目標を非機密にするには: 子アイテム目標または主な成果がある場合は、まずすべてを非機密にするか、削除する必要があります。
  - 子アイテム目標または主な成果を機密目標に追加するには、まずそれらを機密にする必要があります。

既存のOKRの公開設定を変更するには、次の手順に従います:

1. [目標を開く](#view-an-objective)か、[主な成果](#view-a-key-result)を開きます。
1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **非公開に設定**または**公開に設定する**を選択します。

### 非公開OKRを表示できるユーザー名 {#who-can-see-confidential-okrs}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

OKRが非公開に設定されている場合、プロジェクトのプランナーロール以上のロールを持っているユーザーのみがOKRにアクセスできます。ゲストロールまたは[最小](permissions.md#users-with-minimal-access)ロールを持つユーザーは、変更前に積極的に参加していたとしても、OKRにアクセスできません。

ただし、**Guest role**（ゲストロール）を持つユーザーは非公開OKRを作成できますが、自分で作成したOKRのみを表示できます。

ゲストロールを持つユーザー名または非メンバーは、OKRに割り当てられている場合、非公開OKRを表示できます。ゲストユーザーまたは非メンバーが非公開OKRから割り当てを解除されると、そのOKRを表示できなくなります。

必要な権限を持たないユーザー名の検索結果には、非公開OKRは表示されません。

### 機密OKRインジケーター {#confidential-okr-indicators}

機密OKRは、いくつかの点で通常のOKRとは視覚的に異なります。OKRの一覧表示では、非公開として設定されているOKRの横に非公開（{{< icon name="eye-slash" >}}）アイコンが表示されます。

[十分な権限](#who-can-see-confidential-okrs)がない場合、非公開OKRは一切表示できません。

同様に、OKR内では、パンくずリストのすぐ横に非公開（{{< icon name="eye-slash" >}}）アイコンが表示されます。

標準から非公開へ、またはその逆へのすべての変更は、OKRのコメントのシステムノートに表示されます。例:

- {{< icon name="eye-slash" >}} Jo Garciaが5分前にイシューを非公開にしました
- {{< icon name="eye" >}} Jo Garciaがたった今、イシューを全員に公開しました

## ディスカッションをロックする {#lock-discussion}

{{< history >}}

- GitLab 16.9で`work_items_beta`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/398649)されました。デフォルトでは無効になっています。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

OKRでの公開コメントを禁止できます。その場合、プロジェクトメンバーのみがコメントを追加および編集できます。

前提要件: 

- プランナー以上のロールが必要です。

OKRをロックするには:

1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **ディスカッションのロック**を選択します。

システムノートがページの詳細に追加されます。

ディスカッションがロックされた状態でOKRが完了した場合、ディスカッションがロック解除されるまで再オープンすることはできません。

## 2列レイアウト {#two-column-layout}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.2で`work_items_mvc_2`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415077)されました。デフォルトでは無効になっています。この機能は[ベータ版](../policy/development_stages_support.md)です。
- GitLab 16.10で`work_items_beta`という機能フラグに[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/446064)しました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。グループごとに利用できるようにするには、管理者が`work_items_beta`という名前の[機能フラグを有効](../administration/feature_flags/_index.md)にできます。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。この機能は本番環境での使用には対応していません。

{{< /alert >}}

有効にすると、OKRはイシューと同様の2列レイアウトを使用します。左側には説明とスレッド、右側にはラベルや担当者などの属性が表示されます。

この機能は[ベータ版](../policy/development_stages_support.md)です。バグを見つけた場合は、[フィードバックイシューにコメントしてください](https://gitlab.com/gitlab-org/gitlab/-/issues/442090)。

![OKR2列ビュー](img/objective_two_column_view_v16_10.png)

## OKR内のリンクされたアイテム {#linked-items-in-okrs}

{{< history >}}

- GitLab 16.5で`linked_work_items`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416558)されました。デフォルトでは有効になっています。
- GitLab 16.7の[GitLab.comおよびGitLab Self-Managedで有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139394)されました。
- GitLab 16.8で、URLとIDを入力して関連アイテムを追加する機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/427594)されました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150148)になりました。機能フラグ`linked_work_items`は削除されました。
- GitLab 17.0で、必要な最小ロールがレポーター（trueの場合）からゲストに[変更](https://gitlab.com/groups/gitlab-org/-/epics/10267)されました。

{{< /history >}}

リンクされたアイテムは双方向の関係であり、子アイテムの目標と主な成果の下のブロックに表示されます。同じプロジェクト内の目標、主な成果、またはタスクを相互にリンクできます。

この関係は、ユーザーが両方のアイテムを表示できる場合にのみUIに表示されます。

### リンクされたアイテムを追加する {#add-a-linked-item}

前提要件:

- プロジェクトのゲストロール以上が必要です。

アイテムを目標または主な成果にリンクするには:

1. 目標または主な成果の**リンクされたアイテム**セクションで、**追加**を選択します。
1. 2つのアイテム間の関係を次のいずれかの操作を行います:
   - **以下に関係する**
   - **ブロック**
   - **は次の人によってブロックされています:**
1. アイテムの検索テキスト、URL、または参照IDを入力します。
1. リンクするアイテムをすべて追加したら、検索ボックスの下にある**追加**を選択します。

リンクされたすべてのアイテムの追加が完了すると、それらの関係が視覚的にわかりやすく分類されて表示されます。

![ステータスインジケーターを使用して進行状況と依存関係を視覚化し、ブロック、ブロック元、または関連付けられているとして分類されたリンクされた作業アイテム。](img/linked_items_list_v16_5.png)

### リンクされたアイテムを削除する {#remove-a-linked-item}

前提要件:

- プロジェクトのゲストロール以上が必要です。

OKRの**リンクされたアイテム**セクションで、各アイテムの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**削除**を選択します。

双方向の関係性により、いずれのアイテムにも関係が表示されなくなります。
