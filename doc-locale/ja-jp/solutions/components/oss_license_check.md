---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLabでOSSライセンスコンプライアンスを設定するためのガイド。これには、依存関係スキャン、承認ポリシー、およびライセンスリストの最新の状態の維持が含まれます。
title: OSSライセンスチェック
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## はじめに {#getting-started}

### ソリューションコンポーネントをダウンロード {#download-the-solution-component}

1. アカウントチームから招待リクエストコードを入手します。
1. 招待リクエストコードを使用して、[ソリューションコンポーネントのウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードします。

## OSSライブラリのライセンスチェック - GitLab承認ポリシー {#oss-library-license-check---gitlab-policy}

このガイドは、Blue Oak Councilのライセンス評価に基づいて、プロジェクトのライセンスコンプライアンス承認ポリシーを実装するのに役立ちます。この承認ポリシーは、Blue Oak CouncilのGold、Silver、Bronzeの各段階に含まれていないライセンスを使用するすべての依存関係に対して、自動的に承認を要求します。

また、提供されているPythonスクリプト`update_licenses.py`を使用して、[ライセンスリストを最新の状態に保つ](#keeping-your-license-list-up-to-date)こともできます。これは、最新の承認済みライセンスをフェッチします。

## 概要 {#overview}

OSSライブラリのライセンスチェックの内容:

- プロジェクト内のすべての依存関係に対する自動ライセンススキャン
- Blue Oak Councilによる[Gold](https://blueoakcouncil.org/list#gold) 、[Silver](https://blueoakcouncil.org/list#silver) 、[Bronze](https://blueoakcouncil.org/list#bronze)と評価されたライセンスを許可するように事前設定された承認ポリシー
- これらの段階にないライセンスの承認ワークフロー

## 前提要件 {#prerequisites}

- GitLab Ultimateプラン
- GitLabインスタンスまたはグループへの管理者アクセス
- プロジェクトで[依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)が有効になっている（これは、[依存関係スキャンの設定](#setting-up-dependency-scanning-from-scratch)手順に従って、指定されたスコープのすべてのプロジェクトに対してオプションで有効化および適用できます）

## 実装ガイド {#implementation-guide}

このガイドでは、主に2つのシナリオを取り上げます:

1. [最初から設定する](#setting-up-from-scratch-using-the-ui)（既存のセキュリティポリシープロジェクトがない場合）
   - [依存関係スキャン](#setting-up-dependency-scanning-from-scratch)をセットアップする
   - [ライセンスコンプライアンスを最初から設定する](#setting-up-license-compliance-from-scratch)
1. [既存の承認ポリシーに追加する](#adding-to-an-existing-policy)（既存のセキュリティポリシープロジェクト）

### 最初から設定する（UIを使用） {#setting-up-from-scratch-using-the-ui}

セキュリティポリシープロジェクトがまだない場合は、プロジェクトを作成し、依存関係スキャンとライセンスコンプライアンスポリシーの両方を設定する必要があります。

#### 依存関係スキャンを最初から設定する {#setting-up-dependency-scanning-from-scratch}

1. まず、この承認ポリシーを適用するグループを特定します。これは、承認ポリシーを適用できる最上位のグループレベルになります（このグループ内のプロジェクトを含めたり、除外したりできます）。
1. そのグループの**セキュリティ** > **ポリシー**ページに移動します。
1. **新規ポリシー**をクリックします。
1. **スキャン実行ポリシー**を選択します。
1. 承認ポリシーの名前を入力します（たとえば、「依存関係スキャンポリシー」）。
1. 説明を入力します（たとえば、「使用されているOSSライセンスのリストを取得するために依存関係スキャンを適用する」）。
1. 「このグループのすべてのプロジェクト」（オプションで例外を設定）または「特定のプロジェクト」（ドロップダウンからプロジェクトを選択）を選択して、**ポリシーのスコープ**を設定します。
1. **アクション**セクションで、（デフォルトの）「シークレット検出」ではなく、「依存関係スキャン」を選択します。
1. **条件**セクションで、すべてのコミット時ではなく、スケジュールに従ってスキャンを実行する場合は、「トリガー:」を「スケジュール:」に変更することもできます。
1. **ポリシーの作成**をクリックします。

#### ライセンスコンプライアンスを最初から設定する {#setting-up-license-compliance-from-scratch}

依存関係スキャンを設定したら、次の手順に従ってライセンスコンプライアンスポリシーを設定します:

1. 同じグループの**セキュリティ** > **ポリシー**ページに戻ります。
1. **新規ポリシー**をクリックします。
1. **マージリクエスト承認ポリシー**を選択します。
1. 承認ポリシーの名前を入力します（たとえば、「OSSコンプライアンスポリシー」）。
1. 説明を入力します（たとえば、「Blue Oak CouncilのGold、Silver、またはBronzeの段階に含まれていないライセンスをブロックする」）。
1. 「このグループのすべてのプロジェクト」（オプションで例外を設定）または「特定のプロジェクト」（ドロップダウンからプロジェクトを選択）を選択して、**ポリシーのスコープ**を設定します。
1. **ルール**セクションで「スキャンタイプの選択」ドロップダウンをクリックし、**ライセンススキャン**を選択します。
1. ターゲットブランチを設定します（デフォルトはすべての保護ブランチ）。
1. 「ステータス:」ドロップダウンを**Newly detected**（新たに検出された）または**既存**に変更します（承認ポリシーを新しい依存関係のみに適用するか、既存の依存関係にも適用するかによって異なります）。
1. **IMPORTANT**（重要）: 「ライセンス:」ドロップダウンをデフォルトの「一致」から**次を除く**に変更します（これにより、承認されていないライセンスをブロックするために承認ポリシーが正しく機能するようになります）。
1. **アクション**セクションまで下にスクロールし、必要な承認の数を設定します。
1. 「承認者タイプの選択」ドロップダウンで、承認を提供するユーザー、グループ、またはロールを選択します（「新しい承認者の追加」をクリックすると、同じルールに複数の承認者タイプを追加できます）。
1. 「プロジェクト承認設定をオーバーライド」セクションを設定し、必要に応じてデフォルト設定を変更します。
1. ページの上部までスクロールして、`.yaml mode`をクリックします。
1. YAMLエディタで、`license_types`セクションを見つけ、[ポリシー設定の完了](#complete-policy-configuration)セクションから承認されたライセンスの完全なリストで置き換えます。このセクションは次のようになります:

```yaml
rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    # Replace this section with the full list of licenses from the Complete Policy Configuration section
    - MIT License
    - Apache License 2.0
    # etc...
```

1. **ポリシーの作成**をクリックします。

### 既存の承認ポリシーに追加する {#adding-to-an-existing-policy}

すでにセキュリティポリシープロジェクトがあるが、依存関係スキャンやライセンスコンプライアンスポリシーがない場合:

1. グループのセキュリティポリシープロジェクトに移動します。
1. `.gitlab/security-policies/`の`policy.yml`ファイルに移動します。
1. **編集** > **単一のファイルを編集**をクリックします。
1. [ポリシー設定の完了](#complete-policy-configuration)から、`scan_execution_policy`セクションと`approval_policy`セクションを追加します。
1. 以下を確認してください:
   - 既存のYAML構造を維持する
   - これらのセクションを、他のトップレベルのセクションと同じレベルに配置する
   - `user_approvers_ids`、`group_approvers_ids`、または`role_approvers`を設定します（必要なのは1つのみ）。
     - `YOUR_USER_ID_HERE`または`YOUR_GROUP_ID_HERE`を適切なユーザー/グループIDに置き換えます（ユーザー/グループID（たとえば、1234567）を貼り付けてください。ユーザー名ではありません）。
   - 承認ポリシーからプロジェクトを除外する場合は、`YOUR_PROJECT_ID_HERE`を置き換えます（プロジェクトID（たとえば、1234）を貼り付けてください。プロジェクト名/パスではありません）。
   - 必要な承認の数を設定するには、`approvals_required: 1`を設定します
   - 必要に応じて`approval_settings`セクションを変更します（`true`に設定されたものはすべて、プロジェクトの承認設定をオーバーライドします）
1. **変更をコミットする**をクリックし、新しいブランチにコミットします。**この変更に対するマージリクエストを作成**を選択して、承認ポリシーの変更をマージできるようにします。

## ポリシー設定の完了 {#complete-policy-configuration}

参考までに、ポリシー設定の全体を以下に示します:

```yaml
scan_execution_policy:
- name: License scan policy
  description: Enforces dependency scanning to get a list of OSS licenses used, in
    order to remain compliant with OSS usage guidance.
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
  skip_ci:
    allowed: true
    allowlist:
      users: []
approval_policy:
- name: OSS Compliance Policy
  description: |-
    Block any licenses that are not included in the Blue Oak Council's Gold, Silver, or Bronze tiers.
    https://blueoakcouncil.org/list
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    - BSD-2-Clause Plus Patent License
    - Amazon Digital Services License
    - Apache License 2.0
    - Adobe Postscript AFM License
    - BSD 1-Clause License
    - BSD 2-Clause "Simplified" License
    - BSD 2-Clause FreeBSD License
    - BSD 2-Clause NetBSD License
    - BSD 2-Clause with Views Sentence
    - Boost Software License 1.0
    - DSDP License
    - Educational Community License v1.0
    - Educational Community License v2.0
    - hdparm License
    - ImageMagick License
    - Intel ACPI Software License Agreement
    - ISC License
    - Linux Kernel Variant of OpenIB.org license
    - MIT License
    - MIT License Modern Variant
    - MIT testregex Variant
    - MIT Tom Wu Variant
    - Microsoft Public License
    - Mulan Permissive Software License, Version 1
    - Mup License
    - PostgreSQL License
    - Solderpad Hardware License v0.5
    - Spencer License 99
    - Universal Permissive License v1.0
    - Xerox License
    - Xfig License
    - BSD Zero Clause License
    - Academic Free License v1.1
    - Academic Free License v1.2
    - Academic Free License v2.0
    - Academic Free License v2.1
    - Academic Free License v3.0
    - AMD's plpa_map.c License
    - Apple MIT License
    - Academy of Motion Picture Arts and Sciences BSD
    - ANTLR Software Rights Notice
    - ANTLR Software Rights Notice with license fallback
    - Apache License 1.0
    - Apache License 1.1
    - Artistic License 2.0
    - Bahyph License
    - Barr License
    - bcrypt Solar Designer License
    - BSD 3-Clause "New" or "Revised" License
    - BSD with attribution
    - BSD 3-Clause Clear License
    - Hewlett-Packard BSD variant license
    - Lawrence Berkeley National Labs BSD variant license
    - BSD 3-Clause Modification
    - BSD 3-Clause No Nuclear License 2014
    - BSD 3-Clause No Nuclear Warranty
    - BSD 3-Clause Open MPI Variant
    - BSD 3-Clause Sun Microsystems
    - BSD 4-Clause "Original" or "Old" License
    - BSD 4-Clause Shortened
    - BSD-4-Clause (University of California-Specific)
    - BSD Source Code Attribution
    - bzip2 and libbzip2 License v1.0.5
    - bzip2 and libbzip2 License v1.0.6
    - Creative Commons Zero v1.0 Universal
    - CFITSIO License
    - Clips License
    - CNRI Jython License
    - CNRI Python License
    - CNRI Python Open Source GPL Compatible License Agreement
    - Cube License
    - curl License
    - eGenix.com Public License 1.1.0
    - Entessa Public License v1.0
    - Freetype Project License
    - fwlw License
    - Historical Permission Notice and Disclaimer - Fenneberg-Livingston variant
    - Historical Permission Notice and Disclaimer - sell regexpr variant
    - HTML Tidy License
    - IBM PowerPC Initialization and Boot Software
    - ICU License
    - Info-ZIP License
    - Intel Open Source License
    - JasPer License
    - libpng License
    - PNG Reference Library version 2
    - libtiff License
    - LaTeX Project Public License v1.3c
    - LZMA SDK License (versions 9.22 and beyond)
    - MIT No Attribution
    - Enlightenment License (e16)
    - CMU License
    - enna License
    - feh License
    - MIT Open Group Variant
    - MIT +no-false-attribs license
    - Matrix Template Library License
    - Mulan Permissive Software License, Version 2
    - Multics License
    - Naumen Public License
    - University of Illinois/NCSA Open Source License
    - Net-SNMP License
    - NetCDF license
    - NICTA Public Software License, Version 1.0
    - NIST Software License
    - NTP License
    - Open Government Licence - Canada
    - Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)
    - Open LDAP Public License v2.0.1
    - Open LDAP Public License v2.1
    - Open LDAP Public License v2.2
    - Open LDAP Public License v2.2.1
    - Open LDAP Public License 2.2.2
    - Open LDAP Public License v2.3
    - Open LDAP Public License v2.4
    - Open LDAP Public License v2.5
    - Open LDAP Public License v2.6
    - Open LDAP Public License v2.7
    - Open LDAP Public License v2.8
    - Open Market License
    - OpenSSL License
    - PHP License v3.0
    - PHP License v3.01
    - Plexus Classworlds License
    - Python Software Foundation License 2.0
    - Python License 2.0
    - Ruby License
    - Saxpath License
    - SGI Free Software License B v2.0
    - Standard ML of New Jersey License
    - SunPro License
    - Scheme Widget Library (SWL) Software License Agreement
    - Symlinks License
    - TCL/TK License
    - TCP Wrappers License
    - UCAR License
    - Unicode License Agreement - Data Files and Software (2015)
    - Unicode License Agreement - Data Files and Software (2016)
    - UnixCrypt License
    - The Unlicense
    - Vovida Software License v1.0
    - W3C Software Notice and License (2002-12-31)
    - X11 License
    - XFree86 License 1.1
    - xlock License
    - X.Net License
    - XPP License
    - zlib License
    - zlib/libpng License with Acknowledgment
    - Zope Public License 2.0
    - Zope Public License 2.1
    license_states:
    - newly_detected
    branch_type: default
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers_ids:
    # Replace with the user IDs of your compliance approver(s)
    - YOUR_USER_ID_HERE
    - YOUR_USER_ID_HERE
    group_approvers_ids:
    # Replace with the group IDs of your compliance approver(s)
    - YOUR_GROUP_ID_HERE
    - YOUR_GROUP_ID_HERE
    role_approvers:
    # Replace with the roles of your compliance approver(s)
    - owner
    - maintainer
  - type: send_bot_message
    enabled: true
  approval_settings:
    block_branch_modification: true
    block_group_branch_modification: true
    prevent_pushing_and_force_pushing: true
    prevent_approval_by_author: true
    prevent_approval_by_commit_author: true
    remove_approvals_with_new_commit: true
    require_password_to_approve: false
  fallback_behavior:
    fail: closed
```

## 仕組み {#how-it-works}

1. `scan_execution_policy`セクションは、すべてのブランチで依存関係スキャンを実行するようにGitLabを設定します。これにより、ライセンス承認ポリシーで使用されるCycloneDX形式のソフトウェア部品表ファイルが生成されます。
1. `approval_policy`セクションは、次のルールを作成します:
   - 事前承認されたライセンス（Blue Oak Councilの[Gold](https://blueoakcouncil.org/list#gold) 、[Silver](https://blueoakcouncil.org/list#silver) 、および[Bronze](https://blueoakcouncil.org/list#bronze)段階）のリストが含まれています
   - このリストにないライセンスには承認が必要です
   - 承認されていないライセンスが検出されると、ボットメッセージが送信されます
   - 承認が付与されるまでマージをブロックします

## カスタマイズオプション {#customization-options}

- **承認者**: 承認者は、次の3つの方法で指定できます:
  - `user_approvers_ids`: ライセンスを承認する必要がある個人のユーザー名IDに置き換えます（例: `1234567`）
  - `group_approvers_ids`: 承認者を含むグループIDに置き換えます（例: `9876543`）
  - `role_approvers`: 承認できるロールを指定します。オプションは、`developer`、`maintainer`、または`owner`です。
- **Project Exclusions**（プロジェクトの除外）: 承認ポリシーから除外するには、プロジェクトIDを`policy_scope.projects.excluding`セクションに追加します
- **承認が必要です**: より多くの承認を要求するには、`approvals_required: 1`を変更します
- **Bot messages**（ボットメッセージ）: `send_bot_message`の`enabled: false`を設定して、ボット通知を無効にします
- **プロジェクト承認設定を上書き**をオーバーライド: 必要に応じて`approval_settings`セクションを変更します（`true`に設定されたものはすべて、プロジェクト設定をオーバーライドします）

## ライセンスリストを最新の状態に保つ {#keeping-your-license-list-up-to-date}

承認済みのライセンスのリストがBlue Oak Councilの評価で常に最新の状態になるようにするには、次のPythonスクリプトを使用して最新のライセンスデータをフェッチできます:

```python
import requests

def fetch_license_data():
    url = "https://blueoakcouncil.org/list.json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for bad status codes
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching data: {e}")
        return None

# Fetch and print the data to verify it worked
data = fetch_license_data()
if data:
    # Look through each rating section
    target_tiers = ['Gold', 'Silver', 'Bronze']

    for rating in data['ratings']:
        if rating['name'] in target_tiers:
            # Print each license name in this tier
            for license in rating['licenses']:
                print(f"- {license['name']}")
```

このスクリプトを使用するには:

1. `update_licenses.py`として保存します。
1. リクエストライブラリがまだインストールされていない場合は、`pip install requests`をインストールします。
1. スクリプト`python update_licenses.py`を実行します。
1. 出力（ライセンスのリスト）をコピーして、`policy.yml`ファイルの既存の`license_types`リストを置き換えます。

これにより、承認ポリシーは、常に最新のBlue Oak Councilライセンス評価を反映するようになります。

## トラブルシューティング {#troubleshooting}

### トラブルシューティング: 承認ポリシーが適用されていません {#policy-not-applying}

設定を変更したセキュリティポリシープロジェクトがグループに正しくリンクされていることを確認します。詳細については、[セキュリティポリシープロジェクト](../../user/application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project)へのリンクを参照してください。

### トラブルシューティング: 依存関係スキャンが実行されていません {#dependency-scan-not-running}

依存関係スキャンがCI/CD設定で有効になっていることと、依存関係ファイルが存在することを確認します。詳細については、[依存関係スキャンのトラブルシューティング](../../user/application_security/dependency_scanning/troubleshooting_dependency_scanning.md)を参照してください。

## 追加リソース {#additional-resources}

- [Blue Oak Councilライセンスリスト](https://blueoakcouncil.org/list)
- [GitLabライセンスコンプライアンスドキュメント](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md)
- [マージリクエスト承認ポリシー](../../user/compliance/license_approval_policies.md)
- [GitLab依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)
