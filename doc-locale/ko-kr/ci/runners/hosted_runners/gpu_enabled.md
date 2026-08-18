---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GPU 지원 호스팅 러너
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

GitLab은 ModelOps 또는 HPC를 위한 대규모 언어 모델(LLM)의 학습 또는 배포와 같은 ModelOps 워크로드의 일부로 많은 계산 리소스가 필요한 워크로드를 가속화하기 위해 GPU 지원 호스팅 러너를 제공합니다.

GitLab은 GPU 지원 러너를 Linux에서만 제공합니다. 이 러너들이 어떻게 작동하는지에 대한 자세한 정보는 [Linux의 호스팅 러너](linux.md)를 참조하세요.

## GPU 지원 러너에 사용 가능한 머신 유형 {#machine-types-available-for-gpu-enabled-runners}

Linux x86-64에 사용 가능한 GPU 지원 러너의 머신 유형은 다음과 같습니다.

| 러너 태그                             | vCPU | 메모리 | 스토리지 | GPU                            | GPU 메모리 |
|----------------------------------------|-------|--------|---------|--------------------------------|------------|
| `saas-linux-medium-amd64-gpu-standard` | 4     | 15GB  | 50GB   | 1 NVIDIA Tesla T4 (또는 유사) | 16GB      |

## GPU 드라이버가 포함된 컨테이너 이미지 {#container-images-with-gpu-drivers}

Linux의 GitLab 호스팅 러너와 마찬가지로, 사용자의 작업은 자체 이미지를 제공하는 정책을 사용하여 격리된 가상 머신(VM)에서 실행됩니다. GitLab은 호스트 VM의 GPU를 격리된 환경에 탑재합니다. GPU를 사용하려면 GPU 드라이버가 설치된 Docker 이미지를 사용해야 합니다. NVIDIA GPU의 경우 [CUDA Toolkit](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cuda)을 사용할 수 있습니다.

## 예제 `.gitlab-ci.yml` 파일 {#example-gitlab-ciyml-file}

다음 예제에서 `.gitlab-ci.yml` 파일에는 NVIDIA CUDA 기본 Ubuntu 이미지가 사용됩니다. `script:` 섹션에서 Python을 설치합니다.

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

작업을 실행할 때마다 Tensorflow 또는 XGBoost와 같은 더 큰 라이브러리를 설치하고 싶지 않은 경우, 필요한 모든 구성 요소가 미리 설치된 자체 이미지를 만들 수 있습니다. 이 데모를 보고 GPU 지원 호스팅 러너를 활용하여 XGBoost 모델을 학습하는 방법을 알아보세요:
<div class="video-fallback">
  GitLab GPU 지원 호스팅 러너의 비디오 시연: <a href="https://youtu.be/tElegG4NCZ0">GitLab을 사용하여 XGBoost 모델 학습</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/tElegG4NCZ0" frameborder="0" allowfullscreen> </iframe>
</figure>
