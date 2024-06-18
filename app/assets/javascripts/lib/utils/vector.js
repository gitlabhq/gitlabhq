class Vector {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  eq(x1, y1) {
    return this.x === x1 && this.y === y1;
  }

  neq(x1, y1) {
    return this.x !== x1 || this.y !== y1;
  }

  gte(x1, y1) {
    return this.x >= x1 && this.y >= y1;
  }

  gt(x1, y1) {
    return this.x > x1 && this.y > y1;
  }

  lte(x1, y1) {
    return this.x <= x1 && this.y <= y1;
  }

  lt(x1, y1) {
    return this.x < x1 && this.y < y1;
  }

  map(fn) {
    return new Vector(fn(this.x), fn(this.y));
  }

  mul(scalar) {
    return new Vector(this.x * scalar, this.y * scalar);
  }

  div(scalar) {
    return new Vector(this.x / scalar, this.y / scalar);
  }

  add(x1, y1) {
    return new Vector(this.x + x1, this.y + y1);
  }

  sub(x1, y1) {
    return new Vector(this.x - x1, this.y - y1);
  }

  round() {
    return new Vector(Math.round(this.x), Math.round(this.y));
  }

  floor() {
    return new Vector(Math.floor(this.x), Math.floor(this.y));
  }

  ceil() {
    return new Vector(Math.ceil(this.x), Math.ceil(this.y));
  }

  toSize() {
    return { width: this.x, height: this.y };
  }
}

const vector = (x, y) => new Vector(x, y);

export default vector;
