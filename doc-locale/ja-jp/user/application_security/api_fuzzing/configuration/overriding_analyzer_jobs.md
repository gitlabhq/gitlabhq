---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オーバーライドするAPIファジングジョブ
---

ジョブ定義をオーバーライドする（`variables`、`dependencies`、[`rules`](../../../../ci/yaml/_index.md#rules)のようなプロパティを変更する場合など）には、オーバーライドするDASTジョブと同じ名前でジョブを宣言します。テンプレートの挿入後にこの新しいジョブを配置し、その下に追加のキーを指定します。たとえば、これはターゲットAPIのベースURLを設定します:

```yaml
include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzing_fuzz:
  variables:
    FUZZAPI_TARGET_URL: https://target/api
```
