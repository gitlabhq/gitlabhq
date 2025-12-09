---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GPU対応のホストされるRunner
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLabは、ModelOpsまたはHPC（ModelOpsワークロードの一部としてのLarge Language Models（LLM）のトレーニングやデプロイなど）のために、高コンピューティングのワークロードを高速化するGPU対応のホストされたRunnerを提供します。

GitLabは、GPU対応のRunnerをLinux上でのみ提供します。これらのRunnerの動作方法の詳細については、[Hosted runners on Linux](linux.md)を参照してください

## GPU対応Runnerで利用可能なマシンタイプ {#machine-types-available-for-gpu-enabled-runners}

以下のマシンタイプは、Linux x86-64上のGPU対応Runnerで利用可能です。

| Runnerタグ                             | vCPU | メモリ | ストレージ | GPU                            | GPUメモリ |
|----------------------------------------|-------|--------|---------|--------------------------------|------------|
| `saas-linux-medium-amd64-gpu-standard` | 4     | 15 GB  | 50 GB   | 1 Nvidia Tesla T4（または類似） | 16 GB      |

## GPUドライバー搭載のコンテナイメージ {#container-images-with-gpu-drivers}

Linux上のGitLabホストされたRunnerと同様に、ジョブは、独自のイメージを持ち込むポリシーを持つ、分離された仮想マシン（VM）で実行されます。GitLabは、ホストVMからGPUを分離された環境にマウントします。GPUを使用するには、GPUドライバーがインストールされたDockerイメージを使用する必要があります。Nvidia GPUの場合、[CUDA Toolkit](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cuda)を使用できます。

## `.gitlab-ci.yml`ファイルの例 {#example-gitlab-ciyml-file}

以下の`.gitlab-ci.yml`ファイルの例では、Nvidia CUDAベースのUbuntuイメージが使用されています。`script:`セクションでは、Pythonをインストールします。

```yaml
gpu-job:
  stage: build
  tags:
    - saas-linux-medium-amd64-gpu-standard
  image: nvcr.io/nvidia/cuda:12.1.1-base-ubuntu22.04
  script:
    - apt-get update
    - apt-get install -y python3.10
    - python3.10 --version
```

ジョブを実行するたびにTensorflowやXGBoostなどの大きなライブラリをインストールしたくない場合は、必要なすべてのコンポーネントがプリインストールされた独自のイメージを作成できます。GPU対応のホストされたRunnerを活用してXGBoostモデルをトレーニングする方法については、このデモをご覧ください:
<div class="video-fallback">
  GitLab GPU対応ホストRunnerのビデオデモ: <a href="https://youtu.be/tElegG4NCZ0">Train XGboost models with GitLab</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/tElegG4NCZ0" frameborder="0" allowfullscreen> </iframe>
</figure>
