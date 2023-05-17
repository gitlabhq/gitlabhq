<script>
import { X509_CERTIFICATE_KEY_IDENTIFIER_TITLE } from '../constants';

export default {
  props: {
    subject: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    subjectKeyIdentifier: {
      type: String,
      required: true,
    },
  },
  computed: {
    subjectValues() {
      return this.subject.split(',');
    },
    subjectKeyIdentifierToDisplay() {
      return this.subjectKeyIdentifier.replaceAll(':', ' ');
    },
  },
  i18n: {
    keyIdentifierTitle: X509_CERTIFICATE_KEY_IDENTIFIER_TITLE,
  },
};
</script>

<template>
  <div>
    <strong>{{ title }}</strong>
    <ul class="gl-pl-5">
      <li v-for="value in subjectValues" :key="value" data-testid="subject-value">
        {{ value }}
      </li>
      <li data-testid="key-identifier">
        {{ $options.i18n.keyIdentifierTitle }} {{ subjectKeyIdentifierToDisplay }}
      </li>
    </ul>
  </div>
</template>
