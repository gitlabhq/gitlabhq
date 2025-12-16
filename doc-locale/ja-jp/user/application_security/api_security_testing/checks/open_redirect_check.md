---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オープンリダイレクト
---

## 説明 {#description}

オープンリダイレクトを特定し、攻撃者によって悪用される可能性があるかどうかを判断します。

## 修正 {#remediation}

Webアプリケーションが、信頼できない入力に含まれるURLにリクエストをリダイレクトさせる可能性のある、信頼できない入力を受け入れる場合、検証されていないリダイレクトと転送が可能になります。信頼できないURLの入力を悪意のあるサイトに変更することにより、攻撃者が正常にフィッシング詐欺を開始し、ユーザー認証情報を盗む可能性があります。変更されたリンクのサーバー名が元のサイトと同一であるため、フィッシングの試みはより信頼できる外観になる可能性があります。検証されていないリダイレクトおよび転送アクセス制御チェックに合格するURLを悪意を持って作成し、通常はアクセスできない特権機能に攻撃者を転送するためにも使用できます。

## リンク {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/601.html)
