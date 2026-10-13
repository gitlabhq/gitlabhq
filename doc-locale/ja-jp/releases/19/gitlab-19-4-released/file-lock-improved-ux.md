---
title: ファイルまたはディレクトリをロックしたユーザーを確認する
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
documentation_link: "../../../user/project/file_lock"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/13019
categories: [ Source Code Management ]
level: secondary
weight: 50
---

ファイルがロックされている場合、blobビューアーを離れることなく、ロックしたユーザーと利用可能な操作を確認できるようになりました。

以前は、**ロック済み**ラベルのみが表示され、誰がファイルをロックしたか、自分でロックを解除できるかどうかを確認する方法がありませんでした。現在は、ラベルの横にポップオーバーが表示され、ロックしたユーザーを確認できます。ファイルのロック解除権限がある場合、ポップオーバーにはロック解除アクションが含まれます。権限がない場合は、その理由が説明されます。ロックされたディレクトリの場合、ポップオーバーから変更をブロックしている特定のファイルに直接リンクされます。
