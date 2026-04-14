---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パッケージライセンシング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## ライセンス {#license}

GitLab自体はMITですが、LinuxパッケージのソースはApache-2.0でライセンスされています。

## ライセンスファイルの場所 {#license-file-location}

バージョン8.11以降、Linuxパッケージには、パッケージにバンドルされているすべてのソフトウェアのライセンス情報が含まれています。

パッケージのインストール後、個々のバンドルされたライブラリのライセンスは`/opt/gitlab/LICENSES`ディレクトリにあります。

また、すべてのライセンスをまとめた`LICENSE`ファイルもあります。このコンパイルされたライセンスは`/opt/gitlab/LICENSE`ファイルにあります。

バージョン9.2以降、Linuxパッケージには、`dependency_licenses.json`ファイルが付属しており、ソフトウェアライブラリ、Railsアプリケーションが使用するRuby gem、フロントエンドコンポーネントに必要なJavaScriptライブラリなど、すべてのバンドルされたソフトウェアのバージョンおよびライセンス情報が含まれています。JSON形式であるため、GitLabはこのファイルを解析することができ、自動チェックや検証に利用できます。ファイルは`/opt/gitlab/dependency_licenses.json`にあります。

バージョン11.3以降、ライセンス情報はオンラインでも利用できます。<https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html>

## ライセンスの確認 {#checking-licenses}

Linuxパッケージは、多くの異なるライセンスによってカバーされているコードで構成される多数のソフトウェアで成り立っています。これらのライセンスは、前述のとおり提供およびコンパイルされています。

バージョン8.13以降、GitLabはLinuxパッケージのインストールに追加のステップを設けました。`license_check`ステップは`lib/gitlab/tasks/license_check.rake`を呼び出すことで、スクリプトの先頭にある配列で示された承認済みおよび疑わしいライセンスの現在のリストと、コンパイルされた`LICENSE`ファイルを照合します。このスクリプトは、Linuxパッケージの一部である各ソフトウェアについて、`Good`、`Unknown`、または`Check`のいずれかを出力します。

- `Good`: GitLabおよびLinuxパッケージ内のすべての使用タイプで承認されているライセンスを示します。
- `Unknown`: 「Good」または「Bad」のリストで認識されていないライセンスを示し、使用上の影響について直ちにレビューされるべきものです。
- `Check`: GitLab自体と互換性がない可能性のあるライセンスを示し、したがってコンプライアンスを確保するためにLinuxパッケージの一部としてどのように使用されているかを確認する必要があります。

このリストは、ライセンスに関するGitLab開発ドキュメントから引用されています。しかし、Linuxパッケージの性質上、ライセンスが同じように適用されない場合があります。`git`と`rsync`などです。[GNUライセンスFAQ](https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation)を参照してください。

## ライセンスの謝辞 {#license-acknowledgments}

### libjpeg-turbo - BSD 3条項ライセンス {#libjpeg-turbo---bsd-3-clause-license}

このソフトウェアは、独立JPEGグループの作業の一部に基づいています。

## 商標の使用 {#trademark-usage}

GitLabドキュメント内では、サードパーティテクノロジーやサードパーティエンティティの商標が参照される場合があります。サードパーティテクノロジーやエンティティへの参照を含めるのは、GitLabソフトウェアがそのようなサードパーティテクノロジーとどのように連携するか、または組み合わせて使用されるかを示す例のみを目的としています。すべての商標、資料、ドキュメント、およびその他の知的財産は、そのような第三者の財産のままです。

### 商標の要件 {#trademark-requirements}

GitLab商標の使用は、（随時更新される）当社のガイドラインに定められた基準にコンプライアンスしている必要があります。CHEF®およびすべてのChefマークはProgress Software Corporationが所有しており、[Progress Software商標使用ポリシー](https://www.progress.com/legal/trademarks)に従って使用する必要があります。

GitLabまたはサードパーティの商標をドキュメントで使用する場合、最初の出現箇所で(R)記号を含めます。例えば、「Chef(R)は設定のために使用されます…」のようにします。後続の箇所では、記号を省略しても構いません。

商標オーナーが特定の通知または商標要件を要求する場合、そのような通知または要件は上記に記載する必要があります。
