---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Cron
---

Cronの構文は、ジョブを実行するタイミングをスケジュールするために使用されます。

[パイプラインスケジュール](../../ci/pipelines/schedules.md)を作成したり、[デプロイフリーズ](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze)を設定して意図しないリリースを防いだりするために、cronの構文文字列の使用が必要になる場合があります。

## Cronの構文

Cronのスケジューリングでは、スペースで区切られた5つの数字を使用します。

```plaintext
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
# │ │ │ │ │
# │ │ │ │ │
# │ │ │ │ │
# * * * * * <command to execute>
```

（出典: [Wikipedia](https://en.wikipedia.org/wiki/Cron)）

Cronの構文では、アスタリスク（`*`）は「every（すべて）」を意味するため、次のcron文字列は有効です。

- 毎時0分に1回実行: `0 * * * *`
- 毎日午前0時に1回実行: `0 0 * * *`
- 毎週日曜日の午前0時に1回実行: `0 0 * * 0`
- 毎月1日の午前0時に1回実行: `0 0 1 * *`
- 毎月22日の午前0時に1回実行: `0 0 22 * *`
- 毎月第2月曜日の午前0時に1回実行: `0 0 * * 1#2`
- 毎年1月1日の午前0時に1回実行: `0 0 1 1 *`
- 隔週日曜日の午前9時に実行: `0 9 * * sun%2`
- 毎月2回、1日と15日の午前3時に実行: `0 3 1,15 * *`
  - この構文は[fugit modulo拡張機能](https://github.com/floraison/fugit#the-modulo-extension)でサポートされています。

Cronの完全なドキュメントについては、[crontab(5) — Linux manual page（crontab(5) — Linuxマニュアルページ（英語））](https://man7.org/linux/man-pages/man5/crontab.5.html)を参照してください。LinuxまたはMacOSのターミナルで`man 5 crontab`と入力すると、このドキュメントをオフラインで参照できます。

## Cronの例

```plaintext
# Run at 7:00pm every day:
0 19 * * *

# Run every minute on the 3rd of June:
* * 3 6 *

# Run at 06:30 every Friday:
30 6 * * 5
```

cronスケジュールの記述例については、[crontab.guru](https://crontab.guru/examples.html)でさらに確認できます。

## GitLabにおけるCronの構文文字列の解析方法

GitLabでは、サーバー上でCronの構文文字列を解析するために[`fugit`](https://github.com/floraison/fugit)を使用し、ブラウザ上でCronの構文を検証するために[cron-validator](https://github.com/TheCloudConnectors/cron-validator)を使用しています。また、ブラウザ上でcronを人間が読める文字列に変換するために[`cRonstrue`](https://github.com/bradymholt/cRonstrue)を使用しています。
