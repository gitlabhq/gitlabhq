/* eslint-disable no-undef, no-alert */

export default class HelloWorld {
  constructor(name) {
    this.message = `Hello ${name}!`;
  }

  sayHello() {
    alert(this.message);
  }
}
