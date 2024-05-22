import vector from '~/lib/utils/vector';

describe('vector', () => {
  it('should create a vector with the correct x and y values', () => {
    const v = vector(2, 3);
    expect(v.x).toBe(2);
    expect(v.y).toBe(3);
  });

  it('should correctly compare equality with eq', () => {
    const v = vector(2, 3);
    expect(v.eq(2, 3)).toBe(true);
    expect(v.eq(3, 2)).toBe(false);
  });

  it('should correctly compare inequality with neq', () => {
    const v = vector(2, 3);
    expect(v.neq(3, 2)).toBe(true);
    expect(v.neq(2, 3)).toBe(false);
  });

  it('should correctly compare greater than or equal with gte', () => {
    const v = vector(2, 3);
    expect(v.gte(2, 3)).toBe(true);
    expect(v.gte(1, 2)).toBe(true);
    expect(v.gte(1, 4)).toBe(false);
  });

  it('should correctly compare greater than with gt', () => {
    const v = vector(2, 3);
    expect(v.gt(2, 3)).toBe(false);
    expect(v.gt(1, 2)).toBe(true);
    expect(v.gt(1, 4)).toBe(false);
  });

  it('should correctly compare less than or equal with lte', () => {
    const v = vector(2, 3);
    expect(v.lte(2, 3)).toBe(true);
    expect(v.lte(3, 2)).toBe(false);
    expect(v.lte(1, 4)).toBe(false);
  });

  it('should correctly compare less than with lt', () => {
    const v = vector(2, 3);
    expect(v.lt(2, 3)).toBe(false);
    expect(v.lt(3, 2)).toBe(false);
    expect(v.lt(1, 4)).toBe(false);
  });

  it('should correctly map the vector with map', () => {
    const v = vector(2, 3);
    const mapped = v.map((n) => n * 2);
    expect(mapped.x).toBe(4);
    expect(mapped.y).toBe(6);
  });

  it('should correctly multiply the vector with a scalar with mul', () => {
    const v = vector(2, 3);
    const multiplied = v.mul(2);
    expect(multiplied.x).toBe(4);
    expect(multiplied.y).toBe(6);
  });

  it('should correctly divide the vector by a scalar with div', () => {
    const v = vector(2, 3);
    const divided = v.div(2);
    expect(divided.x).toBe(1);
    expect(divided.y).toBe(1.5);
  });

  it('should correctly add another vector with add', () => {
    const v = vector(2, 3);
    const added = v.add(1, 2);
    expect(added.x).toBe(3);
    expect(added.y).toBe(5);
  });

  it('should correctly subtract another vector with sub', () => {
    const v = vector(2, 3);
    const subtracted = v.sub(1, 2);
    expect(subtracted.x).toBe(1);
    expect(subtracted.y).toBe(1);
  });

  it('should correctly round the vector with round', () => {
    const v = vector(2.3, 3.6);
    const rounded = v.round();
    expect(rounded.x).toBe(2);
    expect(rounded.y).toBe(4);
  });

  it('should correctly floor the vector with floor', () => {
    const v = vector(2.3, 3.6);
    const floored = v.floor();
    expect(floored.x).toBe(2);
    expect(floored.y).toBe(3);
  });

  it('should correctly ceil the vector with ceil', () => {
    const v = vector(2.3, 3.6);
    const ceiled = v.ceil();
    expect(ceiled.x).toBe(3);
    expect(ceiled.y).toBe(4);
  });

  it('should correctly convert the vector to a size object with toSize', () => {
    const v = vector(2, 3);
    const size = v.toSize();
    expect(size.width).toBe(2);
    expect(size.height).toBe(3);
  });
});
