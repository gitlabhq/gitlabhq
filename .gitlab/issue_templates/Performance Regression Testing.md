<!--
The purpose of this template is to enable teams to self-service performance regression testing. This template works in conjunction with the handbook page https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/ to provide a consistent approach to doing performance regression testing.
-->

## Test Overview

This section provides a space for you to document the test setup and purpose to enable better collaboration and knowledge sharing. This helps reviewers provide meaningful feedback and ensures you can reproduce or modify the test later.

### What are we testing?

<!-- Quick description of what is being tested, include link to relevant work items -->

### Success Criteria

<!-- Quick description of what success looks like -->

### Reference Architecture

[X Large (10k users)](https://docs.gitlab.com/administration/reference_architectures/10k_users/) 

### Test Tool

[GitLab Performance Tool (GPT)](https://gitlab.com/gitlab-org/quality/performance) 

### Test Configuration

[60s_200rps.json](https://gitlab.com/gitlab-org/quality/performance/-/blob/main/k6/config/options/60s_200rps.json) 

### Test Image Source

<!-- Note the test image/version/source as described in https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#identify-test-image -->

### Tests Run

<!-- What tests were run, could be the command line used to run the tests -->

---

## Test implementation checklists

This section includes checklists corresponding to the relevant parts of the guide in the handbook. You can use them to track your progress as you follow the guide.

### Test Preparation

- [ ] [Define Testing](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#define-testing)
- [ ] [Identify Success Criteria](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#identify-success-criteria)
- [ ] [Choose Reference Architecture](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#choose-reference-architecture)
- [ ] [Identify Test Image](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#identify-test-image)
- [ ] Documented information from these steps [above](#test-overview)
- [ ] [Prepare GET Configuration](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#prepare-get-configuration)
  - [ ] Updated `gitlab_deb_download_url` with test image (commented out for baseline testing)
  - [ ] Disabled rate limits
- [ ] [Setup Test Infrastructure](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#setup-test-infrastructure)
  - [ ] Provisioned test VM (n2-standard-2 or larger)
  - [ ] Installed GPT on test VM
  - [ ] Created environment config file for GPT

---

### Baseline Testing

- [ ] [Deploy Base Environment](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#deploy-base-environment)
- [ ] [Seed with Performance Data](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#seed-with-performance-data)
- [ ] [Running a Performance Test](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#run-baseline-test)
  - [ ] Executed the chosen tests
  - [ ] Captured test results
  - [ ] Exported Grafana metrics
  - [ ] Results attached to this work item

---

### Upgrade & Testing

- [ ] [Upgrade Environment](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#upgrade-environment)
  - [ ] Applied upgrade to environment
  - [ ] Confirmed new versions running
- [ ] [Run post-upgrade test](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#run-post-upgrade-test)
  - [ ] Executed same tests
  - [ ] Captured test results
  - [ ] Exported Grafana metrics
  - [ ] Results attached to this work item

---

### Analysis & Results

- [ ] [Compare Results](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#compare-results)
  - [ ] Compared baseline vs post-upgrade metrics
  - [ ] Checked against [published thresholds](https://gitlab.com/gitlab-org/reference-architectures/-/wikis/Benchmarks/Latest/10k)
  - [ ] Identified any performance regressions
- [ ] [Interpreting Results](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing/#interpreting-the-results)
  - [ ] Evaluated results against Green/Yellow/Red criteria
  - [ ] Documented key findings

---

### Cleanup

- [ ] [Cleanup Test Environment](https://handbook.gitlab.com/handbook/engineering/testing/self-service-performance-regression-testing#cleanup)
  - [ ] Ran Ansible uninstall playbook `ansible-playbook -i environments/<ENV_NAME>/inventory playbooks/uninstall.yml`
  - [ ] Ran `terraform destroy`
  - [ ] Verified GCP resources cleaned up
  - [ ] Verified external IPs released
  - [ ] Test VM stopped or destroyed

---

## Results

### Comparison Summary

<!-- Update this table with metrics that are relevant to the testing -->

| Metric | Baseline | Post-Upgrade | Change | Status |
| ------ | -------- | ------------ | ------ | ------ |
| Response Time (p95) | [ms] | [ms] | [%] | [ ] Green [ ] Yellow [ ] Red |
| Throughput (RPS) | [rps] | [rps] | [%] | [ ] Green [ ] Yellow [ ] Red |
| Error Rate | [%] | [%] | [%] | [ ] Green [ ] Yellow [ ] Red |
| Memory Usage | [GB] | [GB] | [%] | [ ] Green [ ] Yellow [ ] Red |
| CPU Utilization | [%] | [%] | [%] | [ ] Green [ ] Yellow [ ] Red |

### Key Findings

<!-- Summary of performance impact and any concerning metrics -->

---

## Decision & Escalation

**Overall Status**: [ ] Green (On Track) [ ] Yellow (Needs Attention) [ ] Red (Rework)

**Decision Rationale**: 

<!-- Explain the status and any next steps -->
