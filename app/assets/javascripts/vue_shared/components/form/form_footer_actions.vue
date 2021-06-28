<!-- eslint-disable-next-line vue/no-deprecated-functional-template -->
<template functional>
  <footer class="form-actions d-flex justify-content-between">
    <div><slot name="prepend"></slot></div>
    <div><slot></slot></div>
    <div><slot name="append"></slot></div>
  </footer>
</template>
