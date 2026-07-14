---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TLS 서버 구성
---

## 설명 {#description}

다양한 TLS 서버 구성 이슈를 확인합니다. 서버에서 지원하는 TLS 버전, HMAC, 암호화 방식 및 압축 알고리즘을 확인합니다.

## 수정 {#remediation}

전송 계층 보호가 부족하면 통신이 신뢰할 수 없는 제3자에게 노출되어 웹 애플리케이션을 손상시키거나 민감한 정보를 도용할 수 있는 공격 경로를 제공합니다. 웹사이트는 일반적으로 전송 계층에서 암호화를 제공하기 위해 Secure Sockets Layer/Transport Layer Security(SSL/TLS)를 사용합니다. 그러나 웹사이트가 SSL/TLS를 사용하도록 구성되고 SSL/TLS를 올바르게 사용하도록 구성되지 않으면 웹사이트가 트래픽 가로채기 및 수정에 취약할 수 있습니다.

SSL/TLS는 프로토콜로서 수년에 걸쳐 여러 번의 수정을 거쳤습니다. 각 새로운 버전은 기능을 추가하고 프로토콜의 약점을 수정합니다. 시간이 지남에 따라 프로토콜의 일부 버전은 지원될 경우 취약점이 될 수 있을 정도로 심각하게 손상됩니다. TLS 1.3(2018) 및 TLS 1.2(2008)와 같은 최신 TLS 버전만 지원하는 것이 좋습니다.

압축은 TLS 연결에 대한 측면 채널 공격과 연결되어 있습니다. 압축을 비활성화하면 이러한 공격을 방지할 수 있습니다. 특히 하나의 공격인 CRIME("Compression Ratio Info-leak Made Easy")을 방지할 수 있습니다. CRIME은 클라이언트를 대상으로 하는 공격이지만 서버가 압축을 지원하지 않으면 공격이 완화됩니다.

역사적으로 고급 암호화는 미국 외부로의 수출이 제한되었습니다. 이 때문에 약한 암호만 사용하도록 제한된 클라이언트를 위해 약한 암호화 옵션을 지원하도록 웹사이트가 구성되었습니다. 약한 암호화 방식은 상대적으로 쉽게 깨질 수 있기 때문에 공격에 취약합니다. 일반적인 홈 컴퓨터에서는 2주 미만, 전용 하드웨어를 사용하면 몇 초 정도 소요됩니다.

오늘날 모든 최신 브라우저와 웹사이트는 훨씬 강력한 암호화를 사용하지만 일부 웹사이트는 여전히 오래된 약한 암호화 방식을 지원하도록 구성되어 있습니다. 이 때문에 공격자는 웹사이트에 연결할 때 클라이언트가 더 약한 암호화 방식으로 다운그레이드되도록 강제할 수 있으므로 공격자가 약한 암호화를 깨뜨릴 수 있습니다. 이러한 이유로 서버는 강력한 암호화 방식만 수락하도록 구성되어야 하며 더 약한 암호화 방식을 요청하는 클라이언트에 서비스를 제공하지 않아야 합니다. 또한 일부 웹사이트는 클라이언트가 훨씬 더 강력한 방식을 지원할 수 있음에도 불구하고 더 약한 암호화 방식을 선택하도록 잘못 구성되어 있습니다. OWASP는 약한 암호화 방식 지원 및 잘못된 구성을 포함하여 SSL/TLS 이슈를 테스트하기 위한 가이드를 제공하며 다른 리소스 및 도구도 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/934.html)
