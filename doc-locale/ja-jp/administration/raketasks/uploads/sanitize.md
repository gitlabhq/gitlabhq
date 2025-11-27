---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップロードのサニタイズRakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

EXIFデータは、JPGまたはTIFF画像のアップロードから自動的に削除されます。

EXIFデータには機密情報（GPSの場所など）が含まれている可能性があるため、GitLabの以前のバージョンにアップロードされた既存の画像からEXIFデータを削除できます。

## 前提条件 {#prerequisite}

このRakeタスクを実行するには、システムに`exiftool`がインストールされている必要があります。GitLabのインストール方法により、次のように条件が異なります:

- Linuxパッケージを使用している場合は、すべて設定されています。
- セルフコンパイルインストールを使用している場合は、`exiftool`がインストールされていることを確認してください:

  ```shell
  # Debian/Ubuntu
  sudo apt-get install libimage-exiftool-perl

  # RHEL/CentOS
  sudo yum install perl-Image-ExifTool
  ```

## 既存のアップロードからEXIFデータを削除する {#remove-exif-data-from-existing-uploads}

既存のアップロードからEXIFデータを削除するには、次のコマンドを実行します:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif
```

デフォルトでは、このコマンドは「dry run」モードで実行され、EXIFデータを削除しません。これにより、イメージをサニタイズする必要があるかどうか（およびその数）を確認できます。

このRakeタスクは、次のパラメータを受け入れます。

| パラメータ    | 型    | 説明                                                                                                                 |
|:-------------|:--------|:----------------------------------------------------------------------------------------------------------------------------|
| `start_id`   | 整数 | IDが指定値以上のアップロードのみが処理されます                                                                     |
| `stop_id`    | 整数 | IDが指定値以下のアップロードのみが処理されます                                                                     |
| `dry_run`    | ブール値 | EXIFデータを削除せず、EXIFデータが存在するかどうかのみを確認します。デフォルトは`true`です。                                     |
| `sleep_time` | 浮動小数点数   | 各画像を処理した後、指定された秒数だけ一時停止します。デフォルトは0.3秒です                                            |
| `uploader`   | 文字列  | 指定されたアップローダーのアップロードに対してのみサニタイズを実行します：`FileUploader`、`PersonalFileUploader`、または`NamespaceFileUploader` |
| `since`      | 日付    | 指定された日付よりも新しいアップロードに対してのみサニタイズを実行します。例：`2019-05-01`                                          |

アップロードが多すぎる場合は、サニタイズを高速化できます:

- `sleep_time`をより低い値に設定します。
- 複数のRakeタスクを並行して実行します。各Rakeタスクは、個別のアップロードIDの範囲（`start_id`と`stop_id`を設定）を持ちます。

すべてのアップロードからEXIFデータを削除するには、以下を使用します:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[,,false,] 2>&1 | tee exif.log
```

IDが100〜5000のアップロードからEXIFデータを削除し、各ファイルの後に0.1秒一時停止するには、以下を使用します:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[100,5000,false,0.1] 2>&1 | tee exif.log
```

出力は`exif.log`ファイルに書き込まれます。これは多くの場合長いためです。

サニタイズがアップロードに失敗した場合、エラーメッセージがRakeタスクの出力に表示されます。一般的な理由としては、ストレージにファイルがないか、有効な画像ではないことが挙げられます。

問題を[報告](https://gitlab.com/gitlab-org/gitlab/-/issues/new)し、エラー出力と（可能であれば）画像とともに、イシューのタイトルにプレフィックス「EXIF」を使用します。
