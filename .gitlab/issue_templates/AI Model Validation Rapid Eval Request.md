---
name: AI Model Validation Request
about: Request validation of an AI model for use in GitLab features
description: Use this template to submit AI models for validation by the AI Framework team
labels: "group::ai framework, category::model validation, type::evaluation"
assignees:
  - "@gitlab-ai-framework-team"
---

# AI Model Validation Request

## Introduction

This issue template facilitates the validation of AI models for use within GitLab features. The AI Framework team uses GitLab's **Centralized Evaluation Framework (CEF)** to assess AI models across multiple dimensions including technical performance, quality, legal compliance, and operational feasibility.

### What is the Bridge Process?

The Bridge Process is our streamlined approach to model validation designed to provide rapid feedback while our comprehensive evaluation system continues to evolve. This process includes:

1. **Initial Assessment** (Days 1-2): Basic quality check using predefined prompt subsets and preliminary review of vendor terms and conditions.
2. **Deep Evaluation** (Days 3-4): Comprehensive testing using existing benchmarks and assessment of scalability and integration requirements.
3. **Final Review** (Day 5): Compilation of results, documentation of findings, and stakeholder review.

### What to Expect

- **Turnaround Time**: 5 business days from submission acceptance (when this issue is moved to "in development")
- **Evaluation Report**: You'll receive a comprehensive report outlining performance on relevant benchmarks, integration considerations, and recommendations.
- **Collaboration**: The AI Framework team may reach out with additional questions or requests for information during the validation process.

### Before You Begin

Please gather as much information as possible about the model you're submitting. Complete documentation helps us evaluate models more efficiently and thoroughly.

---

## Model Details

### Basic Information
- **Model Name**: <!-- Full name of the model -->
- **Model Version**: <!-- Specific version to be evaluated -->
- **Developer/Lab**: <!-- Organization that developed the model -->
- **Parent Project**: <!-- Larger initiative this model belongs to, if applicable -->
- **License Type**: <!-- E.g., Open Source, Commercial, Proprietary -->
- **Country of Origin**: <!-- Where the model was developed -->
- **Model Type**: <!-- E.g., Foundation LLM, Fine-tuned LLM, Embeddings, etc. -->
- **Target Approval Date and Why**: <!-- Minimum 5 business days for existing vendors -->

### Technical Specifications
- **Model Size**: <!-- Parameter count or model dimensions -->
- **Supported Hardware Requirements**: <!-- GPU/CPU requirements, memory needs -->
- **Context Window Size**: <!-- Maximum token context -->

### Setup & Deployment
- **Setup Documentation**: <!-- Link to setup instructions -->
- **Model Card**: <!-- Optional - Link to model card, if available -->
- **API Documentation**: 


## Legal & Compliance

Please see [Legal's model intake template for legal approval instructions](#), and link the created issue back here.
