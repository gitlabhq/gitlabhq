(function () { "use strict";
var $estr = function() { return js.Boot.__string_rec(this,''); };
var HxOverrides = function() { }
HxOverrides.__name__ = true;
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
}
HxOverrides.substr = function(s,pos,len) {
	if(pos != null && pos != 0 && len != null && len < 0) return "";
	if(len == null) len = s.length;
	if(pos < 0) {
		pos = s.length + pos;
		if(pos < 0) pos = 0;
	} else if(len < 0) len = s.length + len - pos;
	return s.substr(pos,len);
}
HxOverrides.iter = function(a) {
	return { cur : 0, arr : a, hasNext : function() {
		return this.cur < this.arr.length;
	}, next : function() {
		return this.arr[this.cur++];
	}};
}
var Lambda = function() { }
Lambda.__name__ = true;
Lambda.array = function(it) {
	var a = new Array();
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var i = $it0.next();
		a.push(i);
	}
	return a;
}
Lambda.map = function(it,f) {
	var l = new List();
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		l.add(f(x));
	}
	return l;
}
Lambda.has = function(it,elt) {
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		if(x == elt) return true;
	}
	return false;
}
var List = function() {
	this.length = 0;
};
List.__name__ = true;
List.prototype = {
	iterator: function() {
		return { h : this.h, hasNext : function() {
			return this.h != null;
		}, next : function() {
			if(this.h == null) return null;
			var x = this.h[0];
			this.h = this.h[1];
			return x;
		}};
	}
	,add: function(item) {
		var x = [item];
		if(this.h == null) this.h = x; else this.q[1] = x;
		this.q = x;
		this.length++;
	}
	,__class__: List
}
var IMap = function() { }
IMap.__name__ = true;
var Reflect = function() { }
Reflect.__name__ = true;
Reflect.field = function(o,field) {
	var v = null;
	try {
		v = o[field];
	} catch( e ) {
	}
	return v;
}
Reflect.fields = function(o) {
	var a = [];
	if(o != null) {
		var hasOwnProperty = Object.prototype.hasOwnProperty;
		for( var f in o ) {
		if(f != "__id__" && f != "hx__closures__" && hasOwnProperty.call(o,f)) a.push(f);
		}
	}
	return a;
}
Reflect.isFunction = function(f) {
	return typeof(f) == "function" && !(f.__name__ || f.__ename__);
}
var Std = function() { }
Std.__name__ = true;
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
}
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
}
Std.parseFloat = function(x) {
	return parseFloat(x);
}
var StringBuf = function() {
	this.b = "";
};
StringBuf.__name__ = true;
StringBuf.prototype = {
	addSub: function(s,pos,len) {
		this.b += len == null?HxOverrides.substr(s,pos,null):HxOverrides.substr(s,pos,len);
	}
	,__class__: StringBuf
}
var ValueType = { __ename__ : true, __constructs__ : ["TNull","TInt","TFloat","TBool","TObject","TFunction","TClass","TEnum","TUnknown"] }
ValueType.TNull = ["TNull",0];
ValueType.TNull.toString = $estr;
ValueType.TNull.__enum__ = ValueType;
ValueType.TInt = ["TInt",1];
ValueType.TInt.toString = $estr;
ValueType.TInt.__enum__ = ValueType;
ValueType.TFloat = ["TFloat",2];
ValueType.TFloat.toString = $estr;
ValueType.TFloat.__enum__ = ValueType;
ValueType.TBool = ["TBool",3];
ValueType.TBool.toString = $estr;
ValueType.TBool.__enum__ = ValueType;
ValueType.TObject = ["TObject",4];
ValueType.TObject.toString = $estr;
ValueType.TObject.__enum__ = ValueType;
ValueType.TFunction = ["TFunction",5];
ValueType.TFunction.toString = $estr;
ValueType.TFunction.__enum__ = ValueType;
ValueType.TClass = function(c) { var $x = ["TClass",6,c]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; }
ValueType.TEnum = function(e) { var $x = ["TEnum",7,e]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; }
ValueType.TUnknown = ["TUnknown",8];
ValueType.TUnknown.toString = $estr;
ValueType.TUnknown.__enum__ = ValueType;
var Type = function() { }
Type.__name__ = true;
Type["typeof"] = function(v) {
	var _g = typeof(v);
	switch(_g) {
	case "boolean":
		return ValueType.TBool;
	case "string":
		return ValueType.TClass(String);
	case "number":
		if(Math.ceil(v) == v % 2147483648.0) return ValueType.TInt;
		return ValueType.TFloat;
	case "object":
		if(v == null) return ValueType.TNull;
		var e = v.__enum__;
		if(e != null) return ValueType.TEnum(e);
		var c = v.__class__;
		if(c != null) return ValueType.TClass(c);
		return ValueType.TObject;
	case "function":
		if(v.__name__ || v.__ename__) return ValueType.TObject;
		return ValueType.TFunction;
	case "undefined":
		return ValueType.TNull;
	default:
		return ValueType.TUnknown;
	}
}
Type.enumIndex = function(e) {
	return e[1];
}
var coopy = {}
coopy.Alignment = function() {
	this.map_a2b = new haxe.ds.IntMap();
	this.map_b2a = new haxe.ds.IntMap();
	this.ha = this.hb = 0;
	this.map_count = 0;
	this.reference = null;
	this.meta = null;
	this.order_cache_has_reference = false;
	this.ia = 0;
	this.ib = 0;
};
coopy.Alignment.__name__ = true;
coopy.Alignment.prototype = {
	toOrder2: function() {
		var order = new coopy.Ordering();
		var xa = 0;
		var xas = this.ha;
		var xb = 0;
		var va = new haxe.ds.IntMap();
		var _g1 = 0, _g = this.ha;
		while(_g1 < _g) {
			var i = _g1++;
			va.set(i,i);
		}
		while(va.keys().hasNext() || xb < this.hb) {
			if(xa >= this.ha) xa = 0;
			if(xa < this.ha && this.a2b(xa) == null) {
				if(va.exists(xa)) {
					order.add(xa,-1);
					va.remove(xa);
					xas--;
				}
				xa++;
				continue;
			}
			if(xb < this.hb) {
				var alt = this.b2a(xb);
				if(alt != null) {
					order.add(alt,xb);
					if(va.exists(alt)) {
						va.remove(alt);
						xas--;
					}
					xa = alt + 1;
				} else order.add(-1,xb);
				xb++;
				continue;
			}
			console.log("Oops, alignment problem");
			break;
		}
		return order;
	}
	,toOrder3: function() {
		var ref = this.reference;
		if(ref == null) {
			ref = new coopy.Alignment();
			ref.range(this.ha,this.ha);
			ref.tables(this.ta,this.ta);
			var _g1 = 0, _g = this.ha;
			while(_g1 < _g) {
				var i = _g1++;
				ref.link(i,i);
			}
		}
		var order = new coopy.Ordering();
		if(this.reference == null) order.ignoreParent();
		var xp = 0;
		var xl = 0;
		var xr = 0;
		var hp = this.ha;
		var hl = ref.hb;
		var hr = this.hb;
		var vp = new haxe.ds.IntMap();
		var vl = new haxe.ds.IntMap();
		var vr = new haxe.ds.IntMap();
		var _g = 0;
		while(_g < hp) {
			var i = _g++;
			vp.set(i,i);
		}
		var _g = 0;
		while(_g < hl) {
			var i = _g++;
			vl.set(i,i);
		}
		var _g = 0;
		while(_g < hr) {
			var i = _g++;
			vr.set(i,i);
		}
		var ct_vp = hp;
		var ct_vl = hl;
		var ct_vr = hr;
		var prev = -1;
		var ct = 0;
		var max_ct = (hp + hl + hr) * 10;
		while(ct_vp > 0 || ct_vl > 0 || ct_vr > 0) {
			ct++;
			if(ct > max_ct) {
				console.log("Ordering took too long, something went wrong");
				break;
			}
			if(xp >= hp) xp = 0;
			if(xl >= hl) xl = 0;
			if(xr >= hr) xr = 0;
			if(xp < hp && ct_vp > 0) {
				if(this.a2b(xp) == null && ref.a2b(xp) == null) {
					if(vp.exists(xp)) {
						order.add(-1,-1,xp);
						prev = xp;
						vp.remove(xp);
						ct_vp--;
					}
					xp++;
					continue;
				}
			}
			var zl = null;
			var zr = null;
			if(xl < hl && ct_vl > 0) {
				zl = ref.b2a(xl);
				if(zl == null) {
					if(vl.exists(xl)) {
						order.add(xl,-1,-1);
						vl.remove(xl);
						ct_vl--;
					}
					xl++;
					continue;
				}
			}
			if(xr < hr && ct_vr > 0) {
				zr = this.b2a(xr);
				if(zr == null) {
					if(vr.exists(xr)) {
						order.add(-1,xr,-1);
						vr.remove(xr);
						ct_vr--;
					}
					xr++;
					continue;
				}
			}
			if(zl != null) {
				if(this.a2b(zl) == null) {
					if(vl.exists(xl)) {
						order.add(xl,-1,zl);
						prev = zl;
						vp.remove(zl);
						ct_vp--;
						vl.remove(xl);
						ct_vl--;
						xp = zl + 1;
					}
					xl++;
					continue;
				}
			}
			if(zr != null) {
				if(ref.a2b(zr) == null) {
					if(vr.exists(xr)) {
						order.add(-1,xr,zr);
						prev = zr;
						vp.remove(zr);
						ct_vp--;
						vr.remove(xr);
						ct_vr--;
						xp = zr + 1;
					}
					xr++;
					continue;
				}
			}
			if(zl != null && zr != null && this.a2b(zl) != null && ref.a2b(zr) != null) {
				if(zl == prev + 1 || zr != prev + 1) {
					if(vr.exists(xr)) {
						order.add(ref.a2b(zr),xr,zr);
						prev = zr;
						vp.remove(zr);
						ct_vp--;
						vl.remove(ref.a2b(zr));
						ct_vl--;
						vr.remove(xr);
						ct_vr--;
						xp = zr + 1;
						xl = ref.a2b(zr) + 1;
					}
					xr++;
					continue;
				} else {
					if(vl.exists(xl)) {
						order.add(xl,this.a2b(zl),zl);
						prev = zl;
						vp.remove(zl);
						ct_vp--;
						vl.remove(xl);
						ct_vl--;
						vr.remove(this.a2b(zl));
						ct_vr--;
						xp = zl + 1;
						xr = this.a2b(zl) + 1;
					}
					xl++;
					continue;
				}
			}
			xp++;
			xl++;
			xr++;
		}
		return order;
	}
	,getTargetHeader: function() {
		return this.ib;
	}
	,getSourceHeader: function() {
		return this.ia;
	}
	,getTarget: function() {
		return this.tb;
	}
	,getSource: function() {
		return this.ta;
	}
	,toOrder: function() {
		if(this.order_cache != null) {
			if(this.reference != null) {
				if(!this.order_cache_has_reference) this.order_cache = null;
			}
		}
		if(this.order_cache == null) this.order_cache = this.toOrder3();
		if(this.reference != null) this.order_cache_has_reference = true;
		return this.order_cache;
	}
	,toString: function() {
		return "" + this.map_a2b.toString();
	}
	,count: function() {
		return this.map_count;
	}
	,b2a: function(b) {
		return this.map_b2a.get(b);
	}
	,a2b: function(a) {
		return this.map_a2b.get(a);
	}
	,link: function(a,b) {
		this.map_a2b.set(a,b);
		this.map_b2a.set(b,a);
		this.map_count++;
	}
	,setRowlike: function(flag) {
	}
	,headers: function(ia,ib) {
		this.ia = ia;
		this.ib = ib;
	}
	,tables: function(ta,tb) {
		this.ta = ta;
		this.tb = tb;
	}
	,range: function(ha,hb) {
		this.ha = ha;
		this.hb = hb;
	}
	,__class__: coopy.Alignment
}
coopy.Bag = function() { }
coopy.Bag.__name__ = true;
coopy.Bag.prototype = {
	__class__: coopy.Bag
}
coopy.CellInfo = function() {
};
$hxExpose(coopy.CellInfo, "coopy.CellInfo");
coopy.CellInfo.__name__ = true;
coopy.CellInfo.prototype = {
	toString: function() {
		if(!this.updated) return this.value;
		if(!this.conflicted) return this.lvalue + "::" + this.rvalue;
		return this.pvalue + "||" + this.lvalue + "::" + this.rvalue;
	}
	,__class__: coopy.CellInfo
}
coopy.Change = function(txt) {
	if(txt != null) {
		this.mode = coopy.ChangeType.NOTE_CHANGE;
		this.change = txt;
	} else this.mode = coopy.ChangeType.NO_CHANGE;
};
$hxExpose(coopy.Change, "coopy.Change");
coopy.Change.__name__ = true;
coopy.Change.prototype = {
	toString: function() {
		return (function($this) {
			var $r;
			var _g = $this;
			$r = (function($this) {
				var $r;
				switch( (_g.mode)[1] ) {
				case 0:
					$r = "no change";
					break;
				case 2:
					$r = "local change: " + Std.string($this.remote) + " -> " + Std.string($this.local);
					break;
				case 1:
					$r = "remote change: " + Std.string($this.local) + " -> " + Std.string($this.remote);
					break;
				case 3:
					$r = "conflicting change: " + Std.string($this.parent) + " -> " + Std.string($this.local) + " / " + Std.string($this.remote);
					break;
				case 4:
					$r = "same change: " + Std.string($this.parent) + " -> " + Std.string($this.local) + " / " + Std.string($this.remote);
					break;
				case 5:
					$r = $this.change;
					break;
				}
				return $r;
			}($this));
			return $r;
		}(this));
	}
	,__class__: coopy.Change
}
coopy.ChangeType = { __ename__ : true, __constructs__ : ["NO_CHANGE","REMOTE_CHANGE","LOCAL_CHANGE","BOTH_CHANGE","SAME_CHANGE","NOTE_CHANGE"] }
coopy.ChangeType.NO_CHANGE = ["NO_CHANGE",0];
coopy.ChangeType.NO_CHANGE.toString = $estr;
coopy.ChangeType.NO_CHANGE.__enum__ = coopy.ChangeType;
coopy.ChangeType.REMOTE_CHANGE = ["REMOTE_CHANGE",1];
coopy.ChangeType.REMOTE_CHANGE.toString = $estr;
coopy.ChangeType.REMOTE_CHANGE.__enum__ = coopy.ChangeType;
coopy.ChangeType.LOCAL_CHANGE = ["LOCAL_CHANGE",2];
coopy.ChangeType.LOCAL_CHANGE.toString = $estr;
coopy.ChangeType.LOCAL_CHANGE.__enum__ = coopy.ChangeType;
coopy.ChangeType.BOTH_CHANGE = ["BOTH_CHANGE",3];
coopy.ChangeType.BOTH_CHANGE.toString = $estr;
coopy.ChangeType.BOTH_CHANGE.__enum__ = coopy.ChangeType;
coopy.ChangeType.SAME_CHANGE = ["SAME_CHANGE",4];
coopy.ChangeType.SAME_CHANGE.toString = $estr;
coopy.ChangeType.SAME_CHANGE.__enum__ = coopy.ChangeType;
coopy.ChangeType.NOTE_CHANGE = ["NOTE_CHANGE",5];
coopy.ChangeType.NOTE_CHANGE.toString = $estr;
coopy.ChangeType.NOTE_CHANGE.__enum__ = coopy.ChangeType;
coopy.Compare = function() {
};
$hxExpose(coopy.Compare, "coopy.Compare");
coopy.Compare.__name__ = true;
coopy.Compare.prototype = {
	comparePrimitive: function(ws) {
		var sparent = ws.parent.toString();
		var slocal = ws.local.toString();
		var sremote = ws.remote.toString();
		var c = new coopy.Change();
		c.parent = ws.parent;
		c.local = ws.local;
		c.remote = ws.remote;
		if(sparent == slocal && sparent != sremote) c.mode = coopy.ChangeType.REMOTE_CHANGE; else if(sparent == sremote && sparent != slocal) c.mode = coopy.ChangeType.LOCAL_CHANGE; else if(slocal == sremote && sparent != slocal) c.mode = coopy.ChangeType.SAME_CHANGE; else if(sparent != slocal && sparent != sremote) c.mode = coopy.ChangeType.BOTH_CHANGE; else c.mode = coopy.ChangeType.NO_CHANGE;
		if(c.mode != coopy.ChangeType.NO_CHANGE) ws.report.changes.push(c);
		return true;
	}
	,compareTable: function(ws) {
		ws.p2l = new coopy.TableComparisonState();
		ws.p2r = new coopy.TableComparisonState();
		ws.p2l.a = ws.tparent;
		ws.p2l.b = ws.tlocal;
		ws.p2r.a = ws.tparent;
		ws.p2r.b = ws.tremote;
		var cmp = new coopy.CompareTable();
		cmp.attach(ws.p2l);
		cmp.attach(ws.p2r);
		var c = new coopy.Change();
		c.parent = ws.parent;
		c.local = ws.local;
		c.remote = ws.remote;
		if(ws.p2l.is_equal && !ws.p2r.is_equal) c.mode = coopy.ChangeType.REMOTE_CHANGE; else if(!ws.p2l.is_equal && ws.p2r.is_equal) c.mode = coopy.ChangeType.LOCAL_CHANGE; else if(!ws.p2l.is_equal && !ws.p2r.is_equal) {
			ws.l2r = new coopy.TableComparisonState();
			ws.l2r.a = ws.tlocal;
			ws.l2r.b = ws.tremote;
			cmp.attach(ws.l2r);
			if(ws.l2r.is_equal) c.mode = coopy.ChangeType.SAME_CHANGE; else c.mode = coopy.ChangeType.BOTH_CHANGE;
		} else c.mode = coopy.ChangeType.NO_CHANGE;
		if(c.mode != coopy.ChangeType.NO_CHANGE) ws.report.changes.push(c);
		return true;
	}
	,compareStructured: function(ws) {
		ws.tparent = ws.parent.getTable();
		ws.tlocal = ws.local.getTable();
		ws.tremote = ws.remote.getTable();
		if(ws.tparent == null || ws.tlocal == null || ws.tremote == null) {
			ws.report.changes.push(new coopy.Change("structured comparisons that include non-tables are not available yet"));
			return false;
		}
		return this.compareTable(ws);
	}
	,compare: function(parent,local,remote,report) {
		var ws = new coopy.Workspace();
		ws.parent = parent;
		ws.local = local;
		ws.remote = remote;
		ws.report = report;
		report.clear();
		if(parent == null || local == null || remote == null) {
			report.changes.push(new coopy.Change("only 3-way comparison allowed right now"));
			return false;
		}
		if(parent.hasStructure() || local.hasStructure() || remote.hasStructure()) return this.compareStructured(ws);
		return this.comparePrimitive(ws);
	}
	,__class__: coopy.Compare
}
coopy.CompareFlags = function() {
	this.always_show_header = true;
	this.show_unchanged = false;
	this.unchanged_context = 1;
	this.always_show_order = false;
	this.never_show_order = true;
	this.ordered = true;
};
$hxExpose(coopy.CompareFlags, "coopy.CompareFlags");
coopy.CompareFlags.__name__ = true;
coopy.CompareFlags.prototype = {
	__class__: coopy.CompareFlags
}
coopy.CompareTable = function() {
};
$hxExpose(coopy.CompareTable, "coopy.CompareTable");
coopy.CompareTable.__name__ = true;
coopy.CompareTable.prototype = {
	getIndexes: function() {
		return this.indexes;
	}
	,storeIndexes: function() {
		this.indexes = new Array();
	}
	,compareCore: function() {
		if(this.comp.completed) return false;
		if(!this.comp.is_equal_known) return this.testIsEqual();
		if(!this.comp.has_same_columns_known) return this.testHasSameColumns();
		this.comp.completed = true;
		return false;
	}
	,isEqual2: function(a,b) {
		if(a.get_width() != b.get_width() || a.get_height() != b.get_height()) return false;
		var av = a.getCellView();
		var _g1 = 0, _g = a.get_height();
		while(_g1 < _g) {
			var i = _g1++;
			var _g3 = 0, _g2 = a.get_width();
			while(_g3 < _g2) {
				var j = _g3++;
				if(!av.equals(a.getCell(j,i),b.getCell(j,i))) return false;
			}
		}
		return true;
	}
	,testIsEqual: function() {
		var p = this.comp.p;
		var a = this.comp.a;
		var b = this.comp.b;
		var eq = this.isEqual2(a,b);
		if(eq && p != null) eq = this.isEqual2(p,a);
		this.comp.is_equal = eq;
		this.comp.is_equal_known = true;
		return true;
	}
	,hasSameColumns2: function(a,b) {
		if(a.get_width() != b.get_width()) return false;
		if(a.get_height() == 0 || b.get_height() == 0) return true;
		var av = a.getCellView();
		var _g1 = 0, _g = a.get_width();
		while(_g1 < _g) {
			var i = _g1++;
			var _g3 = i + 1, _g2 = a.get_width();
			while(_g3 < _g2) {
				var j = _g3++;
				if(av.equals(a.getCell(i,0),a.getCell(j,0))) return false;
			}
			if(!av.equals(a.getCell(i,0),b.getCell(i,0))) return false;
		}
		return true;
	}
	,testHasSameColumns: function() {
		var p = this.comp.p;
		var a = this.comp.a;
		var b = this.comp.b;
		var eq = this.hasSameColumns2(a,b);
		if(eq && p != null) eq = this.hasSameColumns2(p,a);
		this.comp.has_same_columns = eq;
		this.comp.has_same_columns_known = true;
		return true;
	}
	,alignColumns: function(align,a,b) {
		align.range(a.get_width(),b.get_width());
		align.tables(a,b);
		align.setRowlike(false);
		var slop = 5;
		var va = a.getCellView();
		var vb = b.getCellView();
		var ra_best = 0;
		var rb_best = 0;
		var ct_best = -1;
		var ma_best = null;
		var mb_best = null;
		var ra_header = 0;
		var rb_header = 0;
		var ra_uniques = 0;
		var rb_uniques = 0;
		var _g = 0;
		while(_g < slop) {
			var ra = _g++;
			if(ra >= a.get_height()) break;
			var _g1 = 0;
			while(_g1 < slop) {
				var rb = _g1++;
				if(rb >= b.get_height()) break;
				var ma = new haxe.ds.StringMap();
				var mb = new haxe.ds.StringMap();
				var ct = 0;
				var uniques = 0;
				var _g3 = 0, _g2 = a.get_width();
				while(_g3 < _g2) {
					var ca = _g3++;
					var key = va.toString(a.getCell(ca,ra));
					if(ma.exists(key)) {
						ma.set(key,-1);
						uniques--;
					} else {
						ma.set(key,ca);
						uniques++;
					}
				}
				if(uniques > ra_uniques) {
					ra_header = ra;
					ra_uniques = uniques;
				}
				uniques = 0;
				var _g3 = 0, _g2 = b.get_width();
				while(_g3 < _g2) {
					var cb = _g3++;
					var key = vb.toString(b.getCell(cb,rb));
					if(mb.exists(key)) {
						mb.set(key,-1);
						uniques--;
					} else {
						mb.set(key,cb);
						uniques++;
					}
				}
				if(uniques > rb_uniques) {
					rb_header = rb;
					rb_uniques = uniques;
				}
				var $it0 = ma.keys();
				while( $it0.hasNext() ) {
					var key = $it0.next();
					var i0 = ma.get(key);
					var i1 = mb.get(key);
					if(i1 >= 0 && i0 >= 0) ct++;
				}
				if(ct > ct_best) {
					ct_best = ct;
					ma_best = ma;
					mb_best = mb;
					ra_best = ra;
					rb_best = rb;
				}
			}
		}
		if(ma_best == null) return;
		var $it1 = ma_best.keys();
		while( $it1.hasNext() ) {
			var key = $it1.next();
			var i0 = ma_best.get(key);
			var i1 = mb_best.get(key);
			if(i1 >= 0 && i0 >= 0) align.link(i0,i1);
		}
		align.headers(ra_header,rb_header);
	}
	,alignCore2: function(align,a,b) {
		if(align.meta == null) align.meta = new coopy.Alignment();
		this.alignColumns(align.meta,a,b);
		var column_order = align.meta.toOrder();
		var common_units = new Array();
		var _g = 0, _g1 = column_order.getList();
		while(_g < _g1.length) {
			var unit = _g1[_g];
			++_g;
			if(unit.l >= 0 && unit.r >= 0 && unit.p != -1) common_units.push(unit);
		}
		align.range(a.get_height(),b.get_height());
		align.tables(a,b);
		align.setRowlike(true);
		var w = a.get_width();
		var ha = a.get_height();
		var hb = b.get_height();
		var av = a.getCellView();
		var N = 5;
		var columns = new Array();
		if(common_units.length > N) {
			var columns_eval = new Array();
			var _g1 = 0, _g = common_units.length;
			while(_g1 < _g) {
				var i = _g1++;
				var ct = 0;
				var mem = new haxe.ds.StringMap();
				var mem2 = new haxe.ds.StringMap();
				var ca = common_units[i].l;
				var cb = common_units[i].r;
				var _g2 = 0;
				while(_g2 < ha) {
					var j = _g2++;
					var key = av.toString(a.getCell(ca,j));
					if(!mem.exists(key)) {
						mem.set(key,1);
						ct++;
					}
				}
				var _g2 = 0;
				while(_g2 < hb) {
					var j = _g2++;
					var key = av.toString(b.getCell(cb,j));
					if(!mem2.exists(key)) {
						mem2.set(key,1);
						ct++;
					}
				}
				columns_eval.push([i,ct]);
			}
			var sorter = function(a1,b1) {
				if(a1[1] < b1[1]) return 1;
				if(a1[1] > b1[1]) return -1;
				return 0;
			};
			columns_eval.sort(sorter);
			columns = Lambda.array(Lambda.map(columns_eval,function(v) {
				return v[0];
			}));
			columns = columns.slice(0,N);
		} else {
			var _g1 = 0, _g = common_units.length;
			while(_g1 < _g) {
				var i = _g1++;
				columns.push(i);
			}
		}
		var top = Math.round(Math.pow(2,columns.length));
		var pending = new haxe.ds.IntMap();
		var _g = 0;
		while(_g < ha) {
			var j = _g++;
			pending.set(j,j);
		}
		var pending_ct = ha;
		var _g = 0;
		while(_g < top) {
			var k = _g++;
			if(k == 0) continue;
			if(pending_ct == 0) break;
			var active_columns = new Array();
			var kk = k;
			var at = 0;
			while(kk > 0) {
				if(kk % 2 == 1) active_columns.push(columns[at]);
				kk >>= 1;
				at++;
			}
			var index = new coopy.IndexPair();
			var _g2 = 0, _g1 = active_columns.length;
			while(_g2 < _g1) {
				var k1 = _g2++;
				var unit = common_units[active_columns[k1]];
				index.addColumns(unit.l,unit.r);
			}
			index.indexTables(a,b);
			var h = a.get_height();
			if(b.get_height() > h) h = b.get_height();
			if(h < 1) h = 1;
			var wide_top_freq = index.getTopFreq();
			var ratio = wide_top_freq;
			ratio /= h + 20;
			if(ratio >= 0.1) continue;
			if(this.indexes != null) this.indexes.push(index);
			var fixed = new Array();
			var $it0 = pending.keys();
			while( $it0.hasNext() ) {
				var j = $it0.next();
				var cross = index.queryLocal(j);
				var spot_a = cross.spot_a;
				var spot_b = cross.spot_b;
				if(spot_a != 1 || spot_b != 1) continue;
				fixed.push(j);
				align.link(j,cross.item_b.lst[0]);
			}
			var _g2 = 0, _g1 = fixed.length;
			while(_g2 < _g1) {
				var j = _g2++;
				pending.remove(fixed[j]);
				pending_ct--;
			}
		}
		align.link(0,0);
	}
	,alignCore: function(align) {
		if(this.comp.p == null) {
			this.alignCore2(align,this.comp.a,this.comp.b);
			return;
		}
		align.reference = new coopy.Alignment();
		this.alignCore2(align,this.comp.p,this.comp.b);
		this.alignCore2(align.reference,this.comp.p,this.comp.a);
		align.meta.reference = align.reference.meta;
	}
	,getComparisonState: function() {
		return this.comp;
	}
	,align: function() {
		var alignment = new coopy.Alignment();
		this.alignCore(alignment);
		return alignment;
	}
	,attach: function(comp) {
		this.comp = comp;
		var more = this.compareCore();
		while(more && comp.run_to_completion) more = this.compareCore();
		return !more;
	}
	,__class__: coopy.CompareTable
}
coopy.Coopy = function() {
};
$hxExpose(coopy.Coopy, "coopy.Coopy");
coopy.Coopy.__name__ = true;
coopy.Coopy.compareTables = function(local,remote) {
	var ct = new coopy.CompareTable();
	var comp = new coopy.TableComparisonState();
	comp.a = local;
	comp.b = remote;
	ct.attach(comp);
	return ct;
}
coopy.Coopy.compareTables3 = function(parent,local,remote) {
	var ct = new coopy.CompareTable();
	var comp = new coopy.TableComparisonState();
	comp.p = parent;
	comp.a = local;
	comp.b = remote;
	ct.attach(comp);
	return ct;
}
coopy.Coopy.randomTests = function() {
	var st = new coopy.SimpleTable(15,6);
	var tab = st;
	console.log("table size is " + tab.get_width() + "x" + tab.get_height());
	tab.setCell(3,4,new coopy.SimpleCell(33));
	console.log("element is " + Std.string(tab.getCell(3,4)));
	var compare = new coopy.Compare();
	var d1 = coopy.ViewedDatum.getSimpleView(new coopy.SimpleCell(10));
	var d2 = coopy.ViewedDatum.getSimpleView(new coopy.SimpleCell(10));
	var d3 = coopy.ViewedDatum.getSimpleView(new coopy.SimpleCell(20));
	var report = new coopy.Report();
	compare.compare(d1,d2,d3,report);
	console.log("report is " + Std.string(report));
	d2 = coopy.ViewedDatum.getSimpleView(new coopy.SimpleCell(50));
	report.clear();
	compare.compare(d1,d2,d3,report);
	console.log("report is " + Std.string(report));
	d2 = coopy.ViewedDatum.getSimpleView(new coopy.SimpleCell(20));
	report.clear();
	compare.compare(d1,d2,d3,report);
	console.log("report is " + Std.string(report));
	d1 = coopy.ViewedDatum.getSimpleView(new coopy.SimpleCell(20));
	report.clear();
	compare.compare(d1,d2,d3,report);
	console.log("report is " + Std.string(report));
	var tv = new coopy.TableView();
	var comp = new coopy.TableComparisonState();
	var ct = new coopy.CompareTable();
	comp.a = st;
	comp.b = st;
	ct.attach(comp);
	console.log("comparing tables");
	var t1 = new coopy.SimpleTable(3,2);
	var t2 = new coopy.SimpleTable(3,2);
	var t3 = new coopy.SimpleTable(3,2);
	var dt1 = new coopy.ViewedDatum(t1,new coopy.TableView());
	var dt2 = new coopy.ViewedDatum(t2,new coopy.TableView());
	var dt3 = new coopy.ViewedDatum(t3,new coopy.TableView());
	compare.compare(dt1,dt2,dt3,report);
	console.log("report is " + Std.string(report));
	t3.setCell(1,1,new coopy.SimpleCell("hello"));
	compare.compare(dt1,dt2,dt3,report);
	console.log("report is " + Std.string(report));
	t1.setCell(1,1,new coopy.SimpleCell("hello"));
	compare.compare(dt1,dt2,dt3,report);
	console.log("report is " + Std.string(report));
	var v = new coopy.Viterbi();
	var td = new coopy.TableDiff(null,null);
	var idx = new coopy.Index();
	var dr = new coopy.DiffRender();
	var cf = new coopy.CompareFlags();
	var hp = new coopy.HighlightPatch(null,null);
	var csv = new coopy.Csv();
	var tm = new coopy.TableModifier(null);
	return 0;
}
coopy.Coopy.cellFor = function(x) {
	if(x == null) return null;
	return new coopy.SimpleCell(x);
}
coopy.Coopy.jsonToTable = function(json) {
	var output = null;
	var _g = 0, _g1 = Reflect.fields(json);
	while(_g < _g1.length) {
		var name = _g1[_g];
		++_g;
		var t = Reflect.field(json,name);
		var columns = Reflect.field(t,"columns");
		if(columns == null) continue;
		var rows = Reflect.field(t,"rows");
		if(rows == null) continue;
		output = new coopy.SimpleTable(columns.length,rows.length);
		var has_hash = false;
		var has_hash_known = false;
		var _g3 = 0, _g2 = rows.length;
		while(_g3 < _g2) {
			var i = _g3++;
			var row = rows[i];
			if(!has_hash_known) {
				if(Reflect.fields(row).length == columns.length) has_hash = true;
				has_hash_known = true;
			}
			if(!has_hash) {
				var lst = row;
				var _g5 = 0, _g4 = columns.length;
				while(_g5 < _g4) {
					var j = _g5++;
					var val = lst[j];
					output.setCell(j,i,coopy.Coopy.cellFor(val));
				}
			} else {
				var _g5 = 0, _g4 = columns.length;
				while(_g5 < _g4) {
					var j = _g5++;
					var val = Reflect.field(row,columns[j]);
					output.setCell(j,i,coopy.Coopy.cellFor(val));
				}
			}
		}
	}
	if(output != null) output.trimBlank();
	return output;
}
coopy.Coopy.coopyhx = function(io) {
	var args = io.args();
	if(args[0] == "--test") return coopy.Coopy.randomTests();
	var more = true;
	var output = null;
	var css_output = null;
	var fragment = false;
	var pretty = true;
	while(more) {
		more = false;
		var _g1 = 0, _g = args.length;
		while(_g1 < _g) {
			var i = _g1++;
			var tag = args[i];
			if(tag == "--output") {
				more = true;
				output = args[i + 1];
				args.splice(i,2);
				break;
			} else if(tag == "--css") {
				more = true;
				fragment = true;
				css_output = args[i + 1];
				args.splice(i,2);
			} else if(tag == "--fragment") {
				more = true;
				fragment = true;
				args.splice(i,1);
			} else if(tag == "--plain") {
				more = true;
				pretty = false;
				args.splice(i,1);
			}
		}
	}
	var cmd = args[0];
	if(args.length < 2 || !Lambda.has(["diff","patch","trim","render"],cmd)) {
		io.writeStderr("Call coopyhx as:\n");
		io.writeStderr("  coopyhx diff [--output OUTPUT.csv] a.csv b.csv\n");
		io.writeStderr("  coopyhx diff [--output OUTPUT.csv] parent.csv a.csv b.csv\n");
		io.writeStderr("  coopyhx diff [--output OUTPUT.jsonbook] a.jsonbook b.jsonbook\n");
		io.writeStderr("  coopyhx patch [--output OUTPUT.csv] source.csv patch.csv\n");
		io.writeStderr("  coopyhx trim [--output OUTPUT.csv] source.csv\n");
		io.writeStderr("  coopyhx render [--output OUTPUT.html] [--css CSS.css] [--fragment] [--plain] diff.csv\n");
		return 1;
	}
	if(output == null) output = "-";
	var cmd1 = args[0];
	var tool = new coopy.Coopy();
	tool.io = io;
	var parent = null;
	var offset = 0;
	if(args.length > 3) {
		parent = tool.loadTable(args[1]);
		offset++;
	}
	var a = tool.loadTable(args[1 + offset]);
	var b = null;
	if(args.length > 2) b = tool.loadTable(args[2 + offset]);
	if(cmd1 == "diff") {
		var ct = coopy.Coopy.compareTables3(parent,a,b);
		var align = ct.align();
		var flags = new coopy.CompareFlags();
		flags.always_show_header = true;
		var td = new coopy.TableDiff(align,flags);
		var o = new coopy.SimpleTable(0,0);
		td.hilite(o);
		tool.saveTable(output,o);
	} else if(cmd1 == "patch") {
		var patcher = new coopy.HighlightPatch(a,b);
		patcher.apply();
		tool.saveTable(output,a);
	} else if(cmd1 == "trim") tool.saveTable(output,a); else if(cmd1 == "render") {
		var renderer = new coopy.DiffRender();
		renderer.usePrettyArrows(pretty);
		renderer.render(a);
		if(!fragment) renderer.completeHtml();
		tool.saveText(output,renderer.html());
		if(css_output != null) tool.saveText(css_output,renderer.sampleCss());
	}
	return 0;
}
coopy.Coopy.main = function() {
	return 0;
}
coopy.Coopy.show = function(t) {
	var w = t.get_width();
	var h = t.get_height();
	var txt = "";
	var _g = 0;
	while(_g < h) {
		var y = _g++;
		var _g1 = 0;
		while(_g1 < w) {
			var x = _g1++;
			txt += Std.string(t.getCell(x,y));
			txt += " ";
		}
		txt += "\n";
	}
	console.log(txt);
}
coopy.Coopy.jsonify = function(t) {
	var workbook = new haxe.ds.StringMap();
	var sheet = new Array();
	var w = t.get_width();
	var h = t.get_height();
	var txt = "";
	var _g = 0;
	while(_g < h) {
		var y = _g++;
		var row = new Array();
		var _g1 = 0;
		while(_g1 < w) {
			var x = _g1++;
			var v = t.getCell(x,y);
			if(v != null) row.push(v.toString()); else row.push(null);
		}
		sheet.push(row);
	}
	workbook.set("sheet",sheet);
	return workbook;
}
coopy.Coopy.prototype = {
	loadTable: function(name) {
		var txt = this.io.getContent(name);
		try {
			var json = haxe.Json.parse(txt);
			this.format_preference = "json";
			var t = coopy.Coopy.jsonToTable(json);
			if(t == null) throw "JSON failed";
			return t;
		} catch( e ) {
			var csv = new coopy.Csv();
			this.format_preference = "csv";
			var data = csv.parseTable(txt);
			var h = data.length;
			var w = 0;
			if(h > 0) w = data[0].length;
			var output = new coopy.SimpleTable(w,h);
			var _g = 0;
			while(_g < h) {
				var i = _g++;
				var _g1 = 0;
				while(_g1 < w) {
					var j = _g1++;
					var val = data[i][j];
					output.setCell(j,i,coopy.Coopy.cellFor(val));
				}
			}
			if(output != null) output.trimBlank();
			return output;
		}
	}
	,saveText: function(name,txt) {
		if(name != "-") this.io.saveContent(name,txt); else this.io.writeStdout(txt);
		return true;
	}
	,saveTable: function(name,t) {
		var txt = "";
		if(this.format_preference != "json") {
			var csv = new coopy.Csv();
			txt = csv.renderTable(t);
		} else txt = haxe.Json.stringify(coopy.Coopy.jsonify(t));
		return this.saveText(name,txt);
	}
	,__class__: coopy.Coopy
}
coopy.CrossMatch = function() {
};
coopy.CrossMatch.__name__ = true;
coopy.CrossMatch.prototype = {
	__class__: coopy.CrossMatch
}
coopy.Csv = function() {
	this.cursor = 0;
	this.row_ended = false;
};
$hxExpose(coopy.Csv, "coopy.Csv");
coopy.Csv.__name__ = true;
coopy.Csv.prototype = {
	parseSingleCell: function(txt) {
		this.cursor = 0;
		this.row_ended = false;
		this.has_structure = false;
		return this.parseCell(txt);
	}
	,parseCell: function(txt) {
		if(txt == null) return null;
		this.row_ended = false;
		var first_non_underscore = txt.length;
		var last_processed = 0;
		var quoting = false;
		var quote = 0;
		var result = "";
		var start = this.cursor;
		var _g1 = this.cursor, _g = txt.length;
		while(_g1 < _g) {
			var i = _g1++;
			var ch = HxOverrides.cca(txt,i);
			last_processed = i;
			if(ch != 95 && i < first_non_underscore) first_non_underscore = i;
			if(this.has_structure) {
				if(!quoting) {
					if(ch == 44) break;
					if(ch == 13 || ch == 10) {
						var ch2 = HxOverrides.cca(txt,i + 1);
						if(ch2 != null) {
							if(ch2 != ch) {
								if(ch2 == 13 || ch2 == 10) last_processed++;
							}
						}
						this.row_ended = true;
						break;
					}
					if(i == this.cursor && (ch == 34 || ch == 39)) {
						quoting = true;
						quote = ch;
						if(i != start) result += String.fromCharCode(ch);
						continue;
					}
					result += String.fromCharCode(ch);
					continue;
				}
				if(ch == quote) {
					quoting = false;
					continue;
				}
			}
			result += String.fromCharCode(ch);
		}
		this.cursor = last_processed;
		if(quote == 0) {
			if(result == "NULL") return null;
			if(first_non_underscore > start) {
				var del = first_non_underscore - start;
				if(HxOverrides.substr(result,del,null) == "NULL") return HxOverrides.substr(result,1,null);
			}
		}
		return result;
	}
	,parseTable: function(txt) {
		this.cursor = 0;
		this.row_ended = false;
		this.has_structure = true;
		var result = new Array();
		var row = new Array();
		while(this.cursor < txt.length) {
			var cell = this.parseCell(txt);
			row.push(cell);
			if(this.row_ended) {
				result.push(row);
				row = new Array();
			}
			this.cursor++;
		}
		return result;
	}
	,renderCell: function(v,d) {
		if(d == null) return "NULL";
		if(v.equals(d,null)) return "NULL";
		var str = v.toString(d);
		var delim = ",";
		var need_quote = false;
		var _g1 = 0, _g = str.length;
		while(_g1 < _g) {
			var i = _g1++;
			var ch = str.charAt(i);
			if(ch == "\"" || ch == "'" || ch == delim || ch == "\r" || ch == "\n" || ch == "\t" || ch == " ") {
				need_quote = true;
				break;
			}
		}
		var result = "";
		if(need_quote) result += "\"";
		var line_buf = "";
		var _g1 = 0, _g = str.length;
		while(_g1 < _g) {
			var i = _g1++;
			var ch = str.charAt(i);
			if(ch == "\"") result += "\"";
			if(ch != "\r" && ch != "\n") {
				if(line_buf.length > 0) {
					result += line_buf;
					line_buf = "";
				}
				result += ch;
			} else line_buf += ch;
		}
		if(need_quote) result += "\"";
		return result;
	}
	,renderTable: function(t) {
		var result = "";
		var w = t.get_width();
		var h = t.get_height();
		var txt = "";
		var v = t.getCellView();
		var _g = 0;
		while(_g < h) {
			var y = _g++;
			var _g1 = 0;
			while(_g1 < w) {
				var x = _g1++;
				if(x > 0) txt += ",";
				txt += this.renderCell(v,t.getCell(x,y));
			}
			txt += "\r\n";
		}
		return txt;
	}
	,__class__: coopy.Csv
}
coopy.DiffRender = function() {
	this.text_to_insert = new Array();
	this.open = false;
	this.pretty_arrows = true;
};
$hxExpose(coopy.DiffRender, "coopy.DiffRender");
coopy.DiffRender.__name__ = true;
coopy.DiffRender.examineCell = function(x,y,value,vcol,vrow,vcorner,cell) {
	cell.category = "";
	cell.category_given_tr = "";
	cell.separator = "";
	cell.conflicted = false;
	cell.updated = false;
	cell.pvalue = cell.lvalue = cell.rvalue = null;
	cell.value = value;
	if(cell.value == null) cell.value = "";
	cell.pretty_value = cell.value;
	if(vrow == null) vrow = "";
	if(vcol == null) vcol = "";
	var removed_column = false;
	if(vrow == ":") cell.category = "move";
	if(vcol.indexOf("+++") >= 0) cell.category_given_tr = cell.category = "add"; else if(vcol.indexOf("---") >= 0) {
		cell.category_given_tr = cell.category = "remove";
		removed_column = true;
	}
	if(vrow == "!") cell.category = "spec"; else if(vrow == "@@") cell.category = "header"; else if(vrow == "+++") {
		if(!removed_column) cell.category = "add";
	} else if(vrow == "---") cell.category = "remove"; else if(vrow.indexOf("->") >= 0) {
		if(!removed_column) {
			var tokens = vrow.split("!");
			var full = vrow;
			var part = tokens[1];
			if(part == null) part = full;
			if(cell.value.indexOf(part) >= 0) {
				var cat = "modify";
				var div = part;
				if(part != full) {
					if(cell.value.indexOf(full) >= 0) {
						div = full;
						cat = "conflict";
						cell.conflicted = true;
					}
				}
				cell.updated = true;
				cell.separator = div;
				tokens = cell.pretty_value.split(div);
				cell.pretty_value = tokens.join(String.fromCharCode(8594));
				cell.category_given_tr = cell.category = cat;
				var offset = cell.conflicted?1:0;
				cell.lvalue = tokens[offset];
				cell.rvalue = tokens[offset + 1];
				if(cell.conflicted) cell.pvalue = tokens[0];
			}
		}
	}
}
coopy.DiffRender.renderCell = function(tt,x,y) {
	var cell = new coopy.CellInfo();
	var corner = tt.getCellText(0,0);
	var off = corner == "@:@"?1:0;
	coopy.DiffRender.examineCell(x,y,tt.getCellText(x,y),tt.getCellText(x,off),tt.getCellText(off,y),corner,cell);
	return cell;
}
coopy.DiffRender.prototype = {
	completeHtml: function() {
		this.text_to_insert.splice(0,0,"<html>\n<meta charset='utf-8'>\n<head>\n<style TYPE='text/css'>\n");
		this.text_to_insert.splice(1,0,this.sampleCss());
		this.text_to_insert.splice(2,0,"</style>\n</head>\n<body>\n<div class='highlighter'>\n");
		this.text_to_insert.push("</div>\n</body>\n</html>\n");
	}
	,sampleCss: function() {
		return ".highlighter .add { \n  background-color: #7fff7f;\n}\n\n.highlighter .remove { \n  background-color: #ff7f7f;\n}\n\n.highlighter td.modify { \n  background-color: #7f7fff;\n}\n\n.highlighter td.conflict { \n  background-color: #f00;\n}\n\n.highlighter .spec { \n  background-color: #aaa;\n}\n\n.highlighter .move { \n  background-color: #ffa;\n}\n\n.highlighter .null { \n  color: #888;\n}\n\n.highlighter table { \n  border-collapse:collapse;\n}\n\n.highlighter td, .highlighter th {\n  border: 1px solid #2D4068;\n  padding: 3px 7px 2px;\n}\n\n.highlighter th, .highlighter .header { \n  background-color: #aaf;\n  font-weight: bold;\n  padding-bottom: 4px;\n  padding-top: 5px;\n  text-align:left;\n}\n\n.highlighter tr:first-child td {\n  border-top: 1px solid #2D4068;\n}\n\n.highlighter td:first-child { \n  border-left: 1px solid #2D4068;\n}\n\n.highlighter td {\n  empty-cells: show;\n}\n";
	}
	,render: function(rows) {
		if(rows.get_width() == 0 || rows.get_height() == 0) return;
		var render = this;
		render.beginTable();
		var change_row = -1;
		var tt = new coopy.TableText(rows);
		var cell = new coopy.CellInfo();
		var corner = tt.getCellText(0,0);
		var off = corner == "@:@"?1:0;
		if(off > 0) {
			if(rows.get_width() <= 1 || rows.get_height() <= 1) return;
		}
		var _g1 = 0, _g = rows.get_height();
		while(_g1 < _g) {
			var row = _g1++;
			var open = false;
			var txt = tt.getCellText(off,row);
			if(txt == null) txt = "";
			coopy.DiffRender.examineCell(0,row,txt,"",txt,corner,cell);
			var row_mode = cell.category;
			if(row_mode == "spec") change_row = row;
			render.beginRow(row_mode);
			var _g3 = 0, _g2 = rows.get_width();
			while(_g3 < _g2) {
				var c = _g3++;
				coopy.DiffRender.examineCell(c,row,tt.getCellText(c,row),change_row >= 0?tt.getCellText(c,change_row):"",txt,corner,cell);
				render.insertCell(this.pretty_arrows?cell.pretty_value:cell.value,cell.category_given_tr);
			}
			render.endRow();
		}
		render.endTable();
	}
	,toString: function() {
		return this.html();
	}
	,html: function() {
		return this.text_to_insert.join("");
	}
	,endTable: function() {
		this.insert("</table>\n");
	}
	,endRow: function() {
		this.insert("</tr>\n");
	}
	,insertCell: function(txt,mode) {
		var cell_decorate = "";
		if(mode != "") cell_decorate = " class=\"" + mode + "\"";
		this.insert(this.td_open + cell_decorate + ">");
		this.insert(txt);
		this.insert(this.td_close);
	}
	,beginRow: function(mode) {
		this.td_open = "<td";
		this.td_close = "</td>";
		var row_class = "";
		if(mode == "header") {
			this.td_open = "<th";
			this.td_close = "</th>";
		} else row_class = mode;
		var tr = "<tr>";
		if(row_class != "") tr = "<tr class=\"" + row_class + "\">";
		this.insert(tr);
	}
	,beginTable: function() {
		this.insert("<table>\n");
	}
	,insert: function(str) {
		this.text_to_insert.push(str);
	}
	,usePrettyArrows: function(flag) {
		this.pretty_arrows = flag;
	}
	,__class__: coopy.DiffRender
}
coopy.Row = function() { }
coopy.Row.__name__ = true;
coopy.Row.prototype = {
	__class__: coopy.Row
}
coopy.HighlightPatch = function(source,patch) {
	this.source = source;
	this.patch = patch;
	this.view = patch.getCellView();
};
$hxExpose(coopy.HighlightPatch, "coopy.HighlightPatch");
coopy.HighlightPatch.__name__ = true;
coopy.HighlightPatch.__interfaces__ = [coopy.Row];
coopy.HighlightPatch.prototype = {
	finishColumns: function() {
		this.needSourceColumns();
		var _g1 = this.payloadCol, _g = this.payloadTop;
		while(_g1 < _g) {
			var i = _g1++;
			var act = this.modifier.get(i);
			var hdr = this.header.get(i);
			if(act == null) act = "";
			if(act == "---") {
				var at = this.patchInSourceCol.get(i);
				var mod = new coopy.HighlightPatchUnit();
				mod.code = act;
				mod.rem = true;
				mod.sourceRow = at;
				mod.patchRow = i;
				this.cmods.push(mod);
			} else if(act == "+++") {
				var mod = new coopy.HighlightPatchUnit();
				mod.code = act;
				mod.add = true;
				var prev = -1;
				var cont = false;
				mod.sourceRow = -1;
				if(this.cmods.length > 0) mod.sourceRow = this.cmods[this.cmods.length - 1].sourceRow;
				if(mod.sourceRow != -1) mod.sourceRowOffset = 1;
				mod.patchRow = i;
				this.cmods.push(mod);
			} else {
				var mod = new coopy.HighlightPatchUnit();
				mod.code = act;
				mod.patchRow = i;
				mod.sourceRow = this.patchInSourceCol.get(i);
				this.cmods.push(mod);
			}
		}
		var at = -1;
		var rat = -1;
		var _g1 = 0, _g = this.cmods.length - 1;
		while(_g1 < _g) {
			var i = _g1++;
			if(this.cmods[i].code != "+++" && this.cmods[i].code != "---") at = this.cmods[i].sourceRow;
			this.cmods[i + 1].sourcePrevRow = at;
			var j = this.cmods.length - 1 - i;
			if(this.cmods[j].code != "+++" && this.cmods[j].code != "---") rat = this.cmods[j].sourceRow;
			this.cmods[j - 1].sourceNextRow = rat;
		}
		var fate = new Array();
		this.permuteColumns();
		if(this.headerMove != null) {
			if(this.colPermutation.length > 0) {
				var _g = 0, _g1 = this.cmods;
				while(_g < _g1.length) {
					var mod = _g1[_g];
					++_g;
					if(mod.sourceRow >= 0) mod.sourceRow = this.colPermutation[mod.sourceRow];
				}
				this.source.insertOrDeleteColumns(this.colPermutation,this.colPermutation.length);
			}
		}
		var len = this.processMods(this.cmods,fate,this.source.get_width());
		this.source.insertOrDeleteColumns(fate,len);
		var _g = 0, _g1 = this.cmods;
		while(_g < _g1.length) {
			var cmod = _g1[_g];
			++_g;
			if(!cmod.rem) {
				if(cmod.add) {
					var _g2 = 0, _g3 = this.mods;
					while(_g2 < _g3.length) {
						var mod = _g3[_g2];
						++_g2;
						if(mod.patchRow != -1 && mod.destRow != -1) {
							var d = this.patch.getCell(cmod.patchRow,mod.patchRow);
							this.source.setCell(cmod.destRow,mod.destRow,d);
						}
					}
					var hdr = this.header.get(cmod.patchRow);
					this.source.setCell(cmod.destRow,0,this.view.toDatum(hdr));
				}
			}
		}
		var _g1 = 0, _g = this.source.get_width();
		while(_g1 < _g) {
			var i = _g1++;
			var name = this.view.toString(this.source.getCell(i,0));
			var next_name = this.headerRename.get(name);
			if(next_name == null) continue;
			this.source.setCell(i,0,this.view.toDatum(next_name));
		}
	}
	,permuteColumns: function() {
		if(this.headerMove == null) return;
		this.colPermutation = new Array();
		this.colPermutationRev = new Array();
		this.computeOrdering(this.cmods,this.colPermutation,this.colPermutationRev,this.source.get_width());
		if(this.colPermutation.length == 0) return;
	}
	,finishRows: function() {
		var fate = new Array();
		this.permuteRows();
		if(this.rowPermutation.length > 0) {
			var _g = 0, _g1 = this.mods;
			while(_g < _g1.length) {
				var mod = _g1[_g];
				++_g;
				if(mod.sourceRow >= 0) mod.sourceRow = this.rowPermutation[mod.sourceRow];
			}
		}
		if(this.rowPermutation.length > 0) this.source.insertOrDeleteRows(this.rowPermutation,this.rowPermutation.length);
		var len = this.processMods(this.mods,fate,this.source.get_height());
		this.source.insertOrDeleteRows(fate,len);
		var _g = 0, _g1 = this.mods;
		while(_g < _g1.length) {
			var mod = _g1[_g];
			++_g;
			if(!mod.rem) {
				if(mod.add) {
					var $it0 = ((function(_e) {
						return function() {
							return _e.iterator();
						};
					})(this.headerPost))();
					while( $it0.hasNext() ) {
						var c = $it0.next();
						var offset = this.patchInSourceCol.get(c);
						if(offset >= 0) this.source.setCell(offset,mod.destRow,this.patch.getCell(c,mod.patchRow));
					}
				} else if(mod.update) {
					this.currentRow = mod.patchRow;
					this.checkAct();
					if(!this.rowInfo.updated) continue;
					var $it1 = ((function(_e1) {
						return function() {
							return _e1.iterator();
						};
					})(this.headerPre))();
					while( $it1.hasNext() ) {
						var c = $it1.next();
						var txt = this.view.toString(this.patch.getCell(c,mod.patchRow));
						coopy.DiffRender.examineCell(0,0,txt,"",this.rowInfo.value,"",this.cellInfo);
						if(!this.cellInfo.updated) continue;
						if(this.cellInfo.conflicted) continue;
						var d = this.view.toDatum(this.csv.parseSingleCell(this.cellInfo.rvalue));
						this.source.setCell(this.patchInSourceCol.get(c),mod.destRow,d);
					}
				}
			}
		}
	}
	,permuteRows: function() {
		this.rowPermutation = new Array();
		this.rowPermutationRev = new Array();
		this.computeOrdering(this.mods,this.rowPermutation,this.rowPermutationRev,this.source.get_height());
	}
	,computeOrdering: function(mods,permutation,permutationRev,dim) {
		var to_unit = new haxe.ds.IntMap();
		var from_unit = new haxe.ds.IntMap();
		var meta_from_unit = new haxe.ds.IntMap();
		var ct = 0;
		var _g = 0;
		while(_g < mods.length) {
			var mod = mods[_g];
			++_g;
			if(mod.add || mod.rem) continue;
			if(mod.sourceRow < 0) continue;
			if(mod.sourcePrevRow >= 0) {
				var v = mod.sourceRow;
				to_unit.set(mod.sourcePrevRow,v);
				v;
				var v = mod.sourcePrevRow;
				from_unit.set(mod.sourceRow,v);
				v;
				if(mod.sourcePrevRow + 1 != mod.sourceRow) ct++;
			}
			if(mod.sourceNextRow >= 0) {
				var v = mod.sourceNextRow;
				to_unit.set(mod.sourceRow,v);
				v;
				var v = mod.sourceRow;
				from_unit.set(mod.sourceNextRow,v);
				v;
				if(mod.sourceRow + 1 != mod.sourceNextRow) ct++;
			}
		}
		if(ct > 0) {
			var cursor = null;
			var logical = null;
			var starts = [];
			var _g = 0;
			while(_g < dim) {
				var i = _g++;
				var u = from_unit.get(i);
				if(u != null) {
					meta_from_unit.set(u,i);
					i;
				} else starts.push(i);
			}
			var used = new haxe.ds.IntMap();
			var len = 0;
			var _g = 0;
			while(_g < dim) {
				var i = _g++;
				if(meta_from_unit.exists(logical)) cursor = meta_from_unit.get(logical); else cursor = null;
				if(cursor == null) cursor = logical = starts.shift();
				if(cursor == null) cursor = 0;
				while(used.exists(cursor)) cursor = (cursor + 1) % dim;
				logical = cursor;
				permutationRev.push(cursor);
				used.set(cursor,1);
				1;
			}
			var _g1 = 0, _g = permutationRev.length;
			while(_g1 < _g) {
				var i = _g1++;
				permutation[i] = -1;
			}
			var _g1 = 0, _g = permutation.length;
			while(_g1 < _g) {
				var i = _g1++;
				permutation[permutationRev[i]] = i;
			}
		}
	}
	,processMods: function(rmods,fate,len) {
		rmods.sort($bind(this,this.sortMods));
		var offset = 0;
		var last = -1;
		var target = 0;
		var _g = 0;
		while(_g < rmods.length) {
			var mod = rmods[_g];
			++_g;
			if(last != -1) {
				var _g2 = last, _g1 = mod.sourceRow + mod.sourceRowOffset;
				while(_g2 < _g1) {
					var i = _g2++;
					fate.push(i + offset);
					target++;
					last++;
				}
			}
			if(mod.rem) {
				fate.push(-1);
				offset--;
			} else if(mod.add) {
				mod.destRow = target;
				target++;
				offset++;
			} else mod.destRow = target;
			if(mod.sourceRow >= 0) {
				last = mod.sourceRow + mod.sourceRowOffset;
				if(mod.rem) last++;
			} else last = -1;
		}
		if(last != -1) {
			var _g = last;
			while(_g < len) {
				var i = _g++;
				fate.push(i + offset);
				target++;
				last++;
			}
		}
		return len + offset;
	}
	,sortMods: function(a,b) {
		if(b.code == "@@" && a.code != "@@") return 1;
		if(a.code == "@@" && b.code != "@@") return -1;
		if(a.sourceRow == -1 && !a.add && b.sourceRow != -1) return 1;
		if(a.sourceRow != -1 && !b.add && b.sourceRow == -1) return -1;
		if(a.sourceRow + a.sourceRowOffset > b.sourceRow + b.sourceRowOffset) return 1;
		if(a.sourceRow + a.sourceRowOffset < b.sourceRow + b.sourceRowOffset) return -1;
		if(a.patchRow > b.patchRow) return 1;
		if(a.patchRow < b.patchRow) return -1;
		return 0;
	}
	,getRowString: function(c) {
		var at = this.sourceInPatchCol.get(c);
		if(at == null) return "NOT_FOUND";
		return this.getPreString(this.getString(at));
	}
	,getPreString: function(txt) {
		this.checkAct();
		if(!this.rowInfo.updated) return txt;
		coopy.DiffRender.examineCell(0,0,txt,"",this.rowInfo.value,"",this.cellInfo);
		if(!this.cellInfo.updated) return txt;
		return this.cellInfo.lvalue;
	}
	,checkAct: function() {
		var act = this.getString(this.rcOffset);
		if(this.rowInfo.value != act) coopy.DiffRender.examineCell(0,0,act,"",act,"",this.rowInfo);
	}
	,applyAction: function(code) {
		var mod = new coopy.HighlightPatchUnit();
		mod.code = code;
		mod.add = code == "+++";
		mod.rem = code == "---";
		mod.update = code == "->";
		this.needSourceIndex();
		if(this.lastSourceRow == -1) this.lastSourceRow = this.lookUp(-1);
		mod.sourcePrevRow = this.lastSourceRow;
		var nextAct = this.actions[this.currentRow + 1];
		if(nextAct != "+++" && nextAct != "...") mod.sourceNextRow = this.lookUp(1);
		if(mod.add) {
			if(this.actions[this.currentRow - 1] != "+++") mod.sourcePrevRow = this.lookUp(-1);
			mod.sourceRow = mod.sourcePrevRow;
			if(mod.sourceRow != -1) mod.sourceRowOffset = 1;
		} else mod.sourceRow = this.lastSourceRow = this.lookUp();
		if(this.actions[this.currentRow + 1] == "") this.lastSourceRow = mod.sourceNextRow;
		mod.patchRow = this.currentRow;
		if(code == "@@") mod.sourceRow = 0;
		this.mods.push(mod);
	}
	,lookUp: function(del) {
		if(del == null) del = 0;
		var at = this.patchInSourceRow.get(this.currentRow + del);
		if(at != null) return at;
		var result = -1;
		this.currentRow += del;
		if(this.currentRow >= 0 && this.currentRow < this.patch.get_height()) {
			var _g = 0, _g1 = this.indexes;
			while(_g < _g1.length) {
				var idx = _g1[_g];
				++_g;
				var match = idx.queryByContent(this);
				if(match.spot_a != 1) continue;
				result = match.item_a.lst[0];
				break;
			}
		}
		this.patchInSourceRow.set(this.currentRow,result);
		result;
		this.currentRow -= del;
		return result;
	}
	,applyHeader: function() {
		var _g1 = this.payloadCol, _g = this.payloadTop;
		while(_g1 < _g) {
			var i = _g1++;
			var name = this.getString(i);
			var mod = this.modifier.get(i);
			var move = false;
			if(mod != null) {
				if(HxOverrides.cca(mod,0) == 58) {
					move = true;
					mod = HxOverrides.substr(mod,1,mod.length);
				}
			}
			this.header.set(i,name);
			if(mod != null) {
				if(HxOverrides.cca(mod,0) == 40) {
					var prev_name = HxOverrides.substr(mod,1,mod.length - 2);
					this.headerPre.set(prev_name,i);
					this.headerPost.set(name,i);
					this.headerRename.set(prev_name,name);
					continue;
				}
			}
			if(mod != "+++") this.headerPre.set(name,i);
			if(mod != "---") this.headerPost.set(name,i);
			if(move) {
				if(this.headerMove == null) this.headerMove = new haxe.ds.StringMap();
				this.headerMove.set(name,1);
			}
		}
		if(this.source.get_height() == 0) this.applyAction("+++");
	}
	,applyMeta: function() {
		var _g1 = this.payloadCol, _g = this.payloadTop;
		while(_g1 < _g) {
			var i = _g1++;
			var name = this.getString(i);
			if(name == "") continue;
			this.modifier.set(i,name);
		}
	}
	,getString: function(c) {
		return this.view.toString(this.getDatum(c));
	}
	,getDatum: function(c) {
		return this.patch.getCell(c,this.currentRow);
	}
	,applyRow: function(r) {
		this.currentRow = r;
		var code = this.actions[r];
		if(r == 0 && this.rcOffset > 0) {
		} else if(code == "@@") {
			this.applyHeader();
			this.applyAction("@@");
		} else if(code == "!") this.applyMeta(); else if(code == "+++") this.applyAction(code); else if(code == "---") this.applyAction(code); else if(code == "+" || code == ":") this.applyAction(code); else if(code.indexOf("->") >= 0) this.applyAction("->"); else this.lastSourceRow = -1;
	}
	,needSourceIndex: function() {
		if(this.indexes != null) return;
		var state = new coopy.TableComparisonState();
		state.a = this.source;
		state.b = this.source;
		var comp = new coopy.CompareTable();
		comp.storeIndexes();
		comp.attach(state);
		comp.align();
		this.indexes = comp.getIndexes();
		this.needSourceColumns();
	}
	,needSourceColumns: function() {
		if(this.sourceInPatchCol != null) return;
		this.sourceInPatchCol = new haxe.ds.IntMap();
		this.patchInSourceCol = new haxe.ds.IntMap();
		var av = this.source.getCellView();
		var _g1 = 0, _g = this.source.get_width();
		while(_g1 < _g) {
			var i = _g1++;
			var name = av.toString(this.source.getCell(i,0));
			var at = this.headerPre.get(name);
			if(at == null) continue;
			this.sourceInPatchCol.set(i,at);
			this.patchInSourceCol.set(at,i);
		}
	}
	,apply: function() {
		this.reset();
		if(this.patch.get_width() < 2) return true;
		if(this.patch.get_height() < 1) return true;
		this.payloadCol = 1 + this.rcOffset;
		this.payloadTop = this.patch.get_width();
		var corner = this.patch.getCellView().toString(this.patch.getCell(0,0));
		this.rcOffset = corner == "@:@"?1:0;
		var _g1 = 0, _g = this.patch.get_height();
		while(_g1 < _g) {
			var r = _g1++;
			var str = this.view.toString(this.patch.getCell(this.rcOffset,r));
			this.actions.push(str != null?str:"");
		}
		var _g1 = 0, _g = this.patch.get_height();
		while(_g1 < _g) {
			var r = _g1++;
			this.applyRow(r);
		}
		this.finishRows();
		this.finishColumns();
		return true;
	}
	,reset: function() {
		this.header = new haxe.ds.IntMap();
		this.headerPre = new haxe.ds.StringMap();
		this.headerPost = new haxe.ds.StringMap();
		this.headerRename = new haxe.ds.StringMap();
		this.headerMove = null;
		this.modifier = new haxe.ds.IntMap();
		this.mods = new Array();
		this.cmods = new Array();
		this.csv = new coopy.Csv();
		this.rcOffset = 0;
		this.currentRow = -1;
		this.rowInfo = new coopy.CellInfo();
		this.cellInfo = new coopy.CellInfo();
		this.sourceInPatchCol = this.patchInSourceCol = null;
		this.patchInSourceRow = new haxe.ds.IntMap();
		this.indexes = null;
		this.lastSourceRow = -1;
		this.actions = new Array();
		this.rowPermutation = null;
		this.rowPermutationRev = null;
		this.colPermutation = null;
		this.colPermutationRev = null;
	}
	,__class__: coopy.HighlightPatch
}
coopy.HighlightPatchUnit = function() {
	this.add = false;
	this.rem = false;
	this.update = false;
	this.sourceRow = -1;
	this.sourceRowOffset = 0;
	this.sourcePrevRow = -1;
	this.sourceNextRow = -1;
	this.destRow = -1;
	this.patchRow = -1;
	this.code = "";
};
$hxExpose(coopy.HighlightPatchUnit, "coopy.HighlightPatchUnit");
coopy.HighlightPatchUnit.__name__ = true;
coopy.HighlightPatchUnit.prototype = {
	toString: function() {
		return this.code + " patchRow " + this.patchRow + " sourceRows " + this.sourcePrevRow + "," + this.sourceRow + "," + this.sourceNextRow + " destRow " + this.destRow;
	}
	,__class__: coopy.HighlightPatchUnit
}
coopy.Index = function() {
	this.items = new haxe.ds.StringMap();
	this.cols = new Array();
	this.keys = new Array();
	this.top_freq = 0;
	this.height = 0;
};
coopy.Index.__name__ = true;
coopy.Index.prototype = {
	getTable: function() {
		return this.indexed_table;
	}
	,toKeyByContent: function(row) {
		var wide = "";
		var _g1 = 0, _g = this.cols.length;
		while(_g1 < _g) {
			var k = _g1++;
			var txt = row.getRowString(this.cols[k]);
			if(txt == "" || txt == "null" || txt == "undefined") continue;
			if(k > 0) wide += " // ";
			wide += txt;
		}
		return wide;
	}
	,toKey: function(t,i) {
		var wide = "";
		if(this.v == null) this.v = t.getCellView();
		var _g1 = 0, _g = this.cols.length;
		while(_g1 < _g) {
			var k = _g1++;
			var d = t.getCell(this.cols[k],i);
			var txt = this.v.toString(d);
			if(txt == "" || txt == "null" || txt == "undefined") continue;
			if(k > 0) wide += " // ";
			wide += txt;
		}
		return wide;
	}
	,indexTable: function(t) {
		this.indexed_table = t;
		var _g1 = 0, _g = t.get_height();
		while(_g1 < _g) {
			var i = _g1++;
			var key;
			if(this.keys.length > i) key = this.keys[i]; else {
				key = this.toKey(t,i);
				this.keys.push(key);
			}
			var item = this.items.get(key);
			if(item == null) {
				item = new coopy.IndexItem();
				this.items.set(key,item);
			}
			var ct = item.add(i);
			if(ct > this.top_freq) this.top_freq = ct;
		}
		this.height = t.get_height();
	}
	,addColumn: function(i) {
		this.cols.push(i);
	}
	,__class__: coopy.Index
}
coopy.IndexItem = function() {
};
coopy.IndexItem.__name__ = true;
coopy.IndexItem.prototype = {
	add: function(i) {
		if(this.lst == null) this.lst = new Array();
		this.lst.push(i);
		return this.lst.length;
	}
	,__class__: coopy.IndexItem
}
coopy.IndexPair = function() {
	this.ia = new coopy.Index();
	this.ib = new coopy.Index();
	this.quality = 0;
};
coopy.IndexPair.__name__ = true;
coopy.IndexPair.prototype = {
	getQuality: function() {
		return this.quality;
	}
	,getTopFreq: function() {
		if(this.ib.top_freq > this.ia.top_freq) return this.ib.top_freq;
		return this.ia.top_freq;
	}
	,queryLocal: function(row) {
		var ka = this.ia.toKey(this.ia.getTable(),row);
		return this.queryByKey(ka);
	}
	,queryByContent: function(row) {
		var result = new coopy.CrossMatch();
		var ka = this.ia.toKeyByContent(row);
		return this.queryByKey(ka);
	}
	,queryByKey: function(ka) {
		var result = new coopy.CrossMatch();
		result.item_a = this.ia.items.get(ka);
		result.item_b = this.ib.items.get(ka);
		result.spot_a = result.spot_b = 0;
		if(ka != "") {
			if(result.item_a != null) result.spot_a = result.item_a.lst.length;
			if(result.item_b != null) result.spot_b = result.item_b.lst.length;
		}
		return result;
	}
	,indexTables: function(a,b) {
		this.ia.indexTable(a);
		this.ib.indexTable(b);
		var good = 0;
		var $it0 = this.ia.items.keys();
		while( $it0.hasNext() ) {
			var key = $it0.next();
			var item_a = this.ia.items.get(key);
			var spot_a = item_a.lst.length;
			var item_b = this.ib.items.get(key);
			var spot_b = 0;
			if(item_b != null) spot_b = item_b.lst.length;
			if(spot_a == 1 && spot_b == 1) good++;
		}
		this.quality = good / Math.max(1.0,a.get_height());
	}
	,addColumns: function(ca,cb) {
		this.ia.addColumn(ca);
		this.ib.addColumn(cb);
	}
	,addColumn: function(i) {
		this.ia.addColumn(i);
		this.ib.addColumn(i);
	}
	,__class__: coopy.IndexPair
}
coopy.Mover = function() {
};
$hxExpose(coopy.Mover, "coopy.Mover");
coopy.Mover.__name__ = true;
coopy.Mover.moveUnits = function(units) {
	var isrc = new Array();
	var idest = new Array();
	var len = units.length;
	var ltop = -1;
	var rtop = -1;
	var in_src = new haxe.ds.IntMap();
	var in_dest = new haxe.ds.IntMap();
	var _g = 0;
	while(_g < len) {
		var i = _g++;
		var unit = units[i];
		if(unit.l >= 0 && unit.r >= 0) {
			if(ltop < unit.l) ltop = unit.l;
			if(rtop < unit.r) rtop = unit.r;
			in_src.set(unit.l,i);
			i;
			in_dest.set(unit.r,i);
			i;
		}
	}
	var v;
	var _g1 = 0, _g = ltop + 1;
	while(_g1 < _g) {
		var i = _g1++;
		v = in_src.get(i);
		if(v != null) isrc.push(v);
	}
	var _g1 = 0, _g = rtop + 1;
	while(_g1 < _g) {
		var i = _g1++;
		v = in_dest.get(i);
		if(v != null) idest.push(v);
	}
	return coopy.Mover.moveWithoutExtras(isrc,idest);
}
coopy.Mover.moveWithExtras = function(isrc,idest) {
	var len = isrc.length;
	var len2 = idest.length;
	var in_src = new haxe.ds.IntMap();
	var in_dest = new haxe.ds.IntMap();
	var _g = 0;
	while(_g < len) {
		var i = _g++;
		in_src.set(isrc[i],i);
		i;
	}
	var _g = 0;
	while(_g < len2) {
		var i = _g++;
		in_dest.set(idest[i],i);
		i;
	}
	var src = new Array();
	var dest = new Array();
	var v;
	var _g = 0;
	while(_g < len) {
		var i = _g++;
		v = isrc[i];
		if(in_dest.exists(v)) src.push(v);
	}
	var _g = 0;
	while(_g < len2) {
		var i = _g++;
		v = idest[i];
		if(in_src.exists(v)) dest.push(v);
	}
	return coopy.Mover.moveWithoutExtras(src,dest);
}
coopy.Mover.moveWithoutExtras = function(src,dest) {
	if(src.length != dest.length) return null;
	if(src.length <= 1) return [];
	var len = src.length;
	var in_src = new haxe.ds.IntMap();
	var blk_len = new haxe.ds.IntMap();
	var blk_src_loc = new haxe.ds.IntMap();
	var blk_dest_loc = new haxe.ds.IntMap();
	var _g = 0;
	while(_g < len) {
		var i = _g++;
		in_src.set(src[i],i);
		i;
	}
	var ct = 0;
	var in_cursor = -2;
	var out_cursor = 0;
	var next;
	var blk = -1;
	var v;
	while(out_cursor < len) {
		v = dest[out_cursor];
		next = in_src.get(v);
		if(next != in_cursor + 1) {
			blk = v;
			ct = 1;
			blk_src_loc.set(blk,next);
			blk_dest_loc.set(blk,out_cursor);
		} else ct++;
		blk_len.set(blk,ct);
		in_cursor = next;
		out_cursor++;
	}
	var blks = new Array();
	var $it0 = blk_len.keys();
	while( $it0.hasNext() ) {
		var k = $it0.next();
		blks.push(k);
	}
	blks.sort(function(a,b) {
		return blk_len.get(b) - blk_len.get(a);
	});
	var moved = new Array();
	while(blks.length > 0) {
		var blk1 = blks.shift();
		var blen = blks.length;
		var ref_src_loc = blk_src_loc.get(blk1);
		var ref_dest_loc = blk_dest_loc.get(blk1);
		var i = blen - 1;
		while(i >= 0) {
			var blki = blks[i];
			var blki_src_loc = blk_src_loc.get(blki);
			var to_left_src = blki_src_loc < ref_src_loc;
			var to_left_dest = blk_dest_loc.get(blki) < ref_dest_loc;
			if(to_left_src != to_left_dest) {
				var ct1 = blk_len.get(blki);
				var _g = 0;
				while(_g < ct1) {
					var j = _g++;
					moved.push(src[blki_src_loc]);
					blki_src_loc++;
				}
				blks.splice(i,1);
			}
			i--;
		}
	}
	return moved;
}
coopy.Mover.prototype = {
	__class__: coopy.Mover
}
coopy.Ordering = function() {
	this.order = new Array();
	this.ignore_parent = false;
};
coopy.Ordering.__name__ = true;
coopy.Ordering.prototype = {
	ignoreParent: function() {
		this.ignore_parent = true;
	}
	,toString: function() {
		var txt = "";
		var _g1 = 0, _g = this.order.length;
		while(_g1 < _g) {
			var i = _g1++;
			if(i > 0) txt += ", ";
			txt += Std.string(this.order[i]);
		}
		return txt;
	}
	,getList: function() {
		return this.order;
	}
	,add: function(l,r,p) {
		if(p == null) p = -2;
		if(this.ignore_parent) p = -2;
		this.order.push(new coopy.Unit(l,r,p));
	}
	,__class__: coopy.Ordering
}
coopy.Report = function() {
	this.changes = new Array();
};
$hxExpose(coopy.Report, "coopy.Report");
coopy.Report.__name__ = true;
coopy.Report.prototype = {
	clear: function() {
		this.changes = new Array();
	}
	,toString: function() {
		return this.changes.toString();
	}
	,__class__: coopy.Report
}
coopy.SimpleCell = function(x) {
	this.datum = x;
};
coopy.SimpleCell.__name__ = true;
coopy.SimpleCell.prototype = {
	toString: function() {
		return this.datum;
	}
	,__class__: coopy.SimpleCell
}
coopy.Table = function() { }
coopy.Table.__name__ = true;
coopy.Table.prototype = {
	__class__: coopy.Table
}
coopy.SimpleTable = function(w,h) {
	this.data = new haxe.ds.IntMap();
	this.w = w;
	this.h = h;
};
$hxExpose(coopy.SimpleTable, "coopy.SimpleTable");
coopy.SimpleTable.__name__ = true;
coopy.SimpleTable.__interfaces__ = [coopy.Table];
coopy.SimpleTable.tableToString = function(tab) {
	var x = "";
	var _g1 = 0, _g = tab.get_height();
	while(_g1 < _g) {
		var i = _g1++;
		var _g3 = 0, _g2 = tab.get_width();
		while(_g3 < _g2) {
			var j = _g3++;
			if(j > 0) x += " ";
			x += Std.string(tab.getCell(j,i));
		}
		x += "\n";
	}
	return x;
}
coopy.SimpleTable.prototype = {
	trimBlank: function() {
		var view = this.getCellView();
		var space = view.toDatum("");
		var more = true;
		while(more) {
			if(this.h == 0) return true;
			var _g1 = 0, _g = this.get_width();
			while(_g1 < _g) {
				var i = _g1++;
				var c = this.getCell(i,this.h - 1);
				if(!(view.equals(c,space) || c == null)) {
					more = false;
					break;
				}
			}
			if(more) this.h--;
		}
		more = true;
		var nw = this.w;
		while(more) {
			if(this.w == 0) break;
			var _g = 0;
			while(_g < 1) {
				var i = _g++;
				var c = this.getCell(nw - 1,i);
				if(!(view.equals(c,space) || c == null)) {
					more = false;
					break;
				}
			}
			if(more) nw--;
		}
		if(nw == this.w) return true;
		var data2 = new haxe.ds.IntMap();
		var _g = 0;
		while(_g < nw) {
			var i = _g++;
			var _g2 = 0, _g1 = this.h;
			while(_g2 < _g1) {
				var r = _g2++;
				var idx = r * this.w + i;
				if(this.data.exists(idx)) {
					var value = this.data.get(idx);
					data2.set(r * nw + i,value);
				}
			}
		}
		this.w = nw;
		this.data = data2;
		return true;
	}
	,insertOrDeleteColumns: function(fate,wfate) {
		var data2 = new haxe.ds.IntMap();
		var _g1 = 0, _g = fate.length;
		while(_g1 < _g) {
			var i = _g1++;
			var j = fate[i];
			if(j != -1) {
				var _g3 = 0, _g2 = this.h;
				while(_g3 < _g2) {
					var r = _g3++;
					var idx = r * this.w + i;
					if(this.data.exists(idx)) {
						var value = this.data.get(idx);
						data2.set(r * wfate + j,value);
					}
				}
			}
		}
		this.w = wfate;
		this.data = data2;
		return true;
	}
	,insertOrDeleteRows: function(fate,hfate) {
		var data2 = new haxe.ds.IntMap();
		var _g1 = 0, _g = fate.length;
		while(_g1 < _g) {
			var i = _g1++;
			var j = fate[i];
			if(j != -1) {
				var _g3 = 0, _g2 = this.w;
				while(_g3 < _g2) {
					var c = _g3++;
					var idx = i * this.w + c;
					if(this.data.exists(idx)) {
						var value = this.data.get(idx);
						data2.set(j * this.w + c,value);
					}
				}
			}
		}
		this.h = hfate;
		this.data = data2;
		return true;
	}
	,clear: function() {
		this.data = new haxe.ds.IntMap();
	}
	,resize: function(w,h) {
		this.w = w;
		this.h = h;
		return true;
	}
	,isResizable: function() {
		return true;
	}
	,getCellView: function() {
		return new coopy.SimpleView();
	}
	,toString: function() {
		return coopy.SimpleTable.tableToString(this);
	}
	,setCell: function(x,y,c) {
		var value = c;
		this.data.set(x + y * this.w,value);
	}
	,getCell: function(x,y) {
		return this.data.get(x + y * this.w);
	}
	,get_size: function() {
		return this.h;
	}
	,get_height: function() {
		return this.h;
	}
	,get_width: function() {
		return this.w;
	}
	,getTable: function() {
		return this;
	}
	,__class__: coopy.SimpleTable
}
coopy.View = function() { }
coopy.View.__name__ = true;
coopy.View.prototype = {
	__class__: coopy.View
}
coopy.SimpleView = function() {
};
$hxExpose(coopy.SimpleView, "coopy.SimpleView");
coopy.SimpleView.__name__ = true;
coopy.SimpleView.__interfaces__ = [coopy.View];
coopy.SimpleView.prototype = {
	toDatum: function(str) {
		if(str == null) return null;
		return str;
	}
	,equals: function(d1,d2) {
		if(d1 == null && d2 == null) return true;
		if(d1 == null && "" + Std.string(d2) == "") return true;
		if("" + Std.string(d1) == "" && d2 == null) return true;
		return "" + Std.string(d1) == "" + Std.string(d2);
	}
	,hasStructure: function(d) {
		return false;
	}
	,getTable: function(d) {
		return null;
	}
	,getBag: function(d) {
		return null;
	}
	,toString: function(d) {
		if(d == null) return null;
		return "" + Std.string(d);
	}
	,__class__: coopy.SimpleView
}
coopy.SparseSheet = function() {
	this.h = this.w = 0;
};
coopy.SparseSheet.__name__ = true;
coopy.SparseSheet.prototype = {
	set: function(x,y,val) {
		var cursor = this.row.get(y);
		if(cursor == null) {
			cursor = new haxe.ds.IntMap();
			this.row.set(y,cursor);
		}
		cursor.set(x,val);
	}
	,get: function(x,y) {
		var cursor = this.row.get(y);
		if(cursor == null) return this.zero;
		var val = cursor.get(x);
		if(val == null) return this.zero;
		return val;
	}
	,nonDestructiveResize: function(w,h,zero) {
		this.w = w;
		this.h = h;
		this.zero = zero;
	}
	,resize: function(w,h,zero) {
		this.row = new haxe.ds.IntMap();
		this.nonDestructiveResize(w,h,zero);
	}
	,__class__: coopy.SparseSheet
}
coopy.TableComparisonState = function() {
	this.reset();
};
$hxExpose(coopy.TableComparisonState, "coopy.TableComparisonState");
coopy.TableComparisonState.__name__ = true;
coopy.TableComparisonState.prototype = {
	reset: function() {
		this.completed = false;
		this.run_to_completion = true;
		this.is_equal_known = false;
		this.is_equal = false;
		this.has_same_columns = false;
		this.has_same_columns_known = false;
	}
	,__class__: coopy.TableComparisonState
}
coopy.TableDiff = function(align,flags) {
	this.align = align;
	this.flags = flags;
};
$hxExpose(coopy.TableDiff, "coopy.TableDiff");
coopy.TableDiff.__name__ = true;
coopy.TableDiff.prototype = {
	test: function() {
		var report = new coopy.Report();
		var order = this.align.toOrder();
		var units = order.getList();
		var has_parent = this.align.reference != null;
		var a;
		var b;
		var p;
		if(has_parent) {
			p = this.align.getSource();
			a = this.align.reference.getTarget();
			b = this.align.getTarget();
		} else {
			a = this.align.getSource();
			b = this.align.getTarget();
			p = a;
		}
		var _g1 = 0, _g = units.length;
		while(_g1 < _g) {
			var i = _g1++;
			var unit = units[i];
			if(unit.p < 0 && unit.l < 0 && unit.r >= 0) report.changes.push(new coopy.Change("inserted row r:" + unit.r));
			if((unit.p >= 0 || !has_parent) && unit.l >= 0 && unit.r < 0) report.changes.push(new coopy.Change("deleted row l:" + unit.l));
			if(unit.l >= 0 && unit.r >= 0) {
				var mod = false;
				var av = a.getCellView();
				var _g3 = 0, _g2 = a.get_width();
				while(_g3 < _g2) {
					var j = _g3++;
				}
			}
		}
		return report;
	}
	,hilite: function(output) {
		if(!output.isResizable()) return false;
		output.resize(0,0);
		output.clear();
		var row_map = new haxe.ds.IntMap();
		var col_map = new haxe.ds.IntMap();
		var order = this.align.toOrder();
		var units = order.getList();
		var has_parent = this.align.reference != null;
		var a;
		var b;
		var p;
		var ra_header = 0;
		var rb_header = 0;
		if(has_parent) {
			p = this.align.getSource();
			a = this.align.reference.getTarget();
			b = this.align.getTarget();
			ra_header = this.align.reference.meta.getTargetHeader();
			rb_header = this.align.meta.getTargetHeader();
		} else {
			a = this.align.getSource();
			b = this.align.getTarget();
			p = a;
			ra_header = this.align.meta.getSourceHeader();
			rb_header = this.align.meta.getTargetHeader();
		}
		var column_order = this.align.meta.toOrder();
		var column_units = column_order.getList();
		var show_rc_numbers = false;
		var row_moves = null;
		var col_moves = null;
		if(this.flags.ordered) {
			row_moves = new haxe.ds.IntMap();
			var moves = coopy.Mover.moveUnits(units);
			var _g1 = 0, _g = moves.length;
			while(_g1 < _g) {
				var i = _g1++;
				row_moves.set(moves[i],i);
				i;
			}
			col_moves = new haxe.ds.IntMap();
			moves = coopy.Mover.moveUnits(column_units);
			var _g1 = 0, _g = moves.length;
			while(_g1 < _g) {
				var i = _g1++;
				col_moves.set(moves[i],i);
				i;
			}
		}
		var outer_reps_needed = this.flags.show_unchanged?1:2;
		var v = a.getCellView();
		var sep = "";
		var conflict_sep = "";
		var schema = new Array();
		var have_schema = false;
		var _g1 = 0, _g = column_units.length;
		while(_g1 < _g) {
			var j = _g1++;
			var cunit = column_units[j];
			var reordered = false;
			if(this.flags.ordered) {
				if(col_moves.exists(j)) reordered = true;
				if(reordered) show_rc_numbers = true;
			}
			var act = "";
			if(cunit.r >= 0 && cunit.lp() == -1) {
				have_schema = true;
				act = "+++";
			}
			if(cunit.r < 0 && cunit.lp() >= 0) {
				have_schema = true;
				act = "---";
			}
			if(cunit.r >= 0 && cunit.lp() >= 0) {
				if(a.get_height() >= ra_header && b.get_height() >= rb_header) {
					var aa = a.getCell(cunit.lp(),ra_header);
					var bb = b.getCell(cunit.r,rb_header);
					if(!v.equals(aa,bb)) {
						have_schema = true;
						act = "(";
						act += v.toString(aa);
						act += ")";
					}
				}
			}
			if(reordered) {
				act = ":" + act;
				have_schema = true;
			}
			schema.push(act);
		}
		if(have_schema) {
			var at = output.get_height();
			output.resize(column_units.length + 1,at + 1);
			output.setCell(0,at,v.toDatum("!"));
			var _g1 = 0, _g = column_units.length;
			while(_g1 < _g) {
				var j = _g1++;
				output.setCell(j + 1,at,v.toDatum(schema[j]));
			}
		}
		var top_line_done = false;
		if(this.flags.always_show_header) {
			var at = output.get_height();
			output.resize(column_units.length + 1,at + 1);
			output.setCell(0,at,v.toDatum("@@"));
			var _g1 = 0, _g = column_units.length;
			while(_g1 < _g) {
				var j = _g1++;
				var cunit = column_units[j];
				if(cunit.r >= 0) {
					if(b.get_height() > 0) output.setCell(j + 1,at,b.getCell(cunit.r,rb_header));
				} else if(cunit.lp() >= 0) {
					if(a.get_height() > 0) output.setCell(j + 1,at,a.getCell(cunit.lp(),ra_header));
				}
				col_map.set(j + 1,cunit);
			}
			top_line_done = true;
		}
		var active = new Array();
		if(!this.flags.show_unchanged) {
			var _g1 = 0, _g = units.length;
			while(_g1 < _g) {
				var i = _g1++;
				active[i] = 0;
			}
		}
		var _g = 0;
		while(_g < outer_reps_needed) {
			var out = _g++;
			if(out == 1) {
				var del = this.flags.unchanged_context;
				if(del > 0) {
					var mark = -del - 1;
					var _g2 = 0, _g1 = units.length;
					while(_g2 < _g1) {
						var i = _g2++;
						if(active[i] == 0 || active[i] == 3) {
							if(i - mark <= del) active[i] = 2; else if(i - mark == del + 1) active[i] = 3;
						} else if(active[i] == 1) mark = i;
					}
					mark = units.length + del + 1;
					var _g2 = 0, _g1 = units.length;
					while(_g2 < _g1) {
						var j = _g2++;
						var i = units.length - 1 - j;
						if(active[i] == 0 || active[i] == 3) {
							if(mark - i <= del) active[i] = 2; else if(mark - i == del + 1) active[i] = 3;
						} else if(active[i] == 1) mark = i;
					}
				}
			}
			var showed_dummy = false;
			var l = -1;
			var r = -1;
			var _g2 = 0, _g1 = units.length;
			while(_g2 < _g1) {
				var i = _g2++;
				var unit = units[i];
				var reordered = false;
				if(this.flags.ordered) {
					if(row_moves.exists(i)) reordered = true;
					if(reordered) show_rc_numbers = true;
				}
				if(unit.r < 0 && unit.l < 0) continue;
				if(unit.r == 0 && unit.lp() == 0 && top_line_done) continue;
				var act = "";
				if(reordered) act = ":";
				var publish = this.flags.show_unchanged;
				var dummy = false;
				if(out == 1) {
					publish = active[i] > 0;
					dummy = active[i] == 3;
					if(dummy && showed_dummy) continue;
					if(!publish) continue;
				}
				if(!dummy) showed_dummy = false;
				var at = output.get_height();
				if(publish) output.resize(column_units.length + 1,at + 1);
				if(dummy) {
					var _g4 = 0, _g3 = column_units.length + 1;
					while(_g4 < _g3) {
						var j = _g4++;
						output.setCell(j,at,v.toDatum("..."));
						showed_dummy = true;
					}
					continue;
				}
				var have_addition = false;
				if(unit.p < 0 && unit.l < 0 && unit.r >= 0) act = "+++";
				if((unit.p >= 0 || !has_parent) && unit.l >= 0 && unit.r < 0) act = "---";
				var _g4 = 0, _g3 = column_units.length;
				while(_g4 < _g3) {
					var j = _g4++;
					var cunit = column_units[j];
					var pp = null;
					var ll = null;
					var rr = null;
					var dd = null;
					var dd_to = null;
					var have_dd_to = false;
					var dd_to_alt = null;
					var have_dd_to_alt = false;
					var have_pp = false;
					var have_ll = false;
					var have_rr = false;
					if(cunit.p >= 0 && unit.p >= 0) {
						pp = p.getCell(cunit.p,unit.p);
						have_pp = true;
					}
					if(cunit.l >= 0 && unit.l >= 0) {
						ll = a.getCell(cunit.l,unit.l);
						have_ll = true;
					}
					if(cunit.r >= 0 && unit.r >= 0) {
						rr = b.getCell(cunit.r,unit.r);
						have_rr = true;
						if((have_pp?cunit.p:cunit.l) < 0) {
							if(rr != null) {
								if(v.toString(rr) != "") have_addition = true;
							}
						}
					}
					if(have_pp) {
						if(!have_rr) dd = pp; else if(v.equals(pp,rr)) dd = pp; else {
							dd = pp;
							dd_to = rr;
							have_dd_to = true;
							if(!v.equals(pp,ll)) {
								if(!v.equals(pp,rr)) {
									dd_to_alt = ll;
									have_dd_to_alt = true;
								}
							}
						}
					} else if(have_ll) {
						if(!have_rr) dd = ll; else if(v.equals(ll,rr)) dd = ll; else {
							dd = ll;
							dd_to = rr;
							have_dd_to = true;
						}
					} else dd = rr;
					var txt = null;
					if(have_dd_to) {
						txt = this.quoteForDiff(v,dd);
						if(sep == "") sep = this.getSeparator(a,b,"->");
						var is_conflict = false;
						if(have_dd_to_alt) {
							if(!v.equals(dd_to,dd_to_alt)) is_conflict = true;
						}
						if(!is_conflict) {
							txt = txt + sep + this.quoteForDiff(v,dd_to);
							if(sep.length > act.length) act = sep;
						} else {
							if(conflict_sep == "") conflict_sep = this.getSeparator(p,a,"!") + sep;
							txt = txt + conflict_sep + this.quoteForDiff(v,dd_to_alt) + conflict_sep + this.quoteForDiff(v,dd_to);
							act = conflict_sep;
						}
					}
					if(act == "" && have_addition) act = "+";
					if(publish) {
						if(txt != null) output.setCell(j + 1,at,v.toDatum(txt)); else output.setCell(j + 1,at,dd);
					}
				}
				if(publish) {
					output.setCell(0,at,v.toDatum(act));
					row_map.set(at,unit);
				}
				if(act != "") {
					if(!publish) {
						if(active != null) active[i] = 1;
					}
				}
			}
		}
		if(!show_rc_numbers) {
			if(this.flags.always_show_order) show_rc_numbers = true; else if(this.flags.ordered) {
				show_rc_numbers = this.isReordered(row_map,output.get_height());
				if(!show_rc_numbers) show_rc_numbers = this.isReordered(col_map,output.get_width());
			}
		}
		if(show_rc_numbers && !this.flags.never_show_order) {
			var target = new Array();
			var _g1 = 0, _g = output.get_width();
			while(_g1 < _g) {
				var i = _g1++;
				target.push(i + 1);
			}
			output.insertOrDeleteColumns(target,output.get_width() + 1);
			this.l_prev = -1;
			this.r_prev = -1;
			var _g1 = 0, _g = output.get_height();
			while(_g1 < _g) {
				var i = _g1++;
				var unit = row_map.get(i);
				if(unit == null) continue;
				output.setCell(0,i,this.reportUnit(unit));
			}
			target = new Array();
			var _g1 = 0, _g = output.get_height();
			while(_g1 < _g) {
				var i = _g1++;
				target.push(i + 1);
			}
			output.insertOrDeleteRows(target,output.get_height() + 1);
			this.l_prev = -1;
			this.r_prev = -1;
			var _g1 = 1, _g = output.get_width();
			while(_g1 < _g) {
				var i = _g1++;
				var unit = col_map.get(i - 1);
				if(unit == null) continue;
				output.setCell(i,0,this.reportUnit(unit));
			}
			output.setCell(0,0,"@:@");
		}
		return true;
	}
	,reportUnit: function(unit) {
		var txt = unit.toString();
		var reordered = false;
		if(unit.l >= 0) {
			if(unit.l < this.l_prev) reordered = true;
			this.l_prev = unit.l;
		}
		if(unit.r >= 0) {
			if(unit.r < this.r_prev) reordered = true;
			this.r_prev = unit.r;
		}
		if(reordered) txt = "[" + txt + "]";
		return txt;
	}
	,isReordered: function(m,ct) {
		var reordered = false;
		var l = -1;
		var r = -1;
		var _g = 0;
		while(_g < ct) {
			var i = _g++;
			var unit = m.get(i);
			if(unit == null) continue;
			if(unit.l >= 0) {
				if(unit.l < l) {
					reordered = true;
					break;
				}
				l = unit.l;
			}
			if(unit.r >= 0) {
				if(unit.r < r) {
					reordered = true;
					break;
				}
				r = unit.r;
			}
		}
		return reordered;
	}
	,quoteForDiff: function(v,d) {
		var nil = "NULL";
		if(v.equals(d,null)) return nil;
		var str = v.toString(d);
		var score = 0;
		var _g1 = 0, _g = str.length;
		while(_g1 < _g) {
			var i = _g1++;
			if(HxOverrides.cca(str,score) != 95) break;
			score++;
		}
		if(HxOverrides.substr(str,score,null) == nil) str = "_" + str;
		return str;
	}
	,getSeparator: function(t,t2,root) {
		var sep = root;
		var w = t.get_width();
		var h = t.get_height();
		var view = t.getCellView();
		var _g = 0;
		while(_g < h) {
			var y = _g++;
			var _g1 = 0;
			while(_g1 < w) {
				var x = _g1++;
				var txt = view.toString(t.getCell(x,y));
				if(txt == null) continue;
				while(txt.indexOf(sep) >= 0) sep = "-" + sep;
			}
		}
		if(t2 != null) {
			w = t2.get_width();
			h = t2.get_height();
			var _g = 0;
			while(_g < h) {
				var y = _g++;
				var _g1 = 0;
				while(_g1 < w) {
					var x = _g1++;
					var txt = view.toString(t2.getCell(x,y));
					if(txt == null) continue;
					while(txt.indexOf(sep) >= 0) sep = "-" + sep;
				}
			}
		}
		return sep;
	}
	,__class__: coopy.TableDiff
}
coopy.TableIO = function() {
};
$hxExpose(coopy.TableIO, "coopy.TableIO");
coopy.TableIO.__name__ = true;
coopy.TableIO.prototype = {
	writeStderr: function(txt) {
	}
	,writeStdout: function(txt) {
	}
	,args: function() {
		return [];
	}
	,saveContent: function(name,txt) {
		return false;
	}
	,getContent: function(name) {
		return "";
	}
	,__class__: coopy.TableIO
}
coopy.TableModifier = function(t) {
	this.t = t;
};
$hxExpose(coopy.TableModifier, "coopy.TableModifier");
coopy.TableModifier.__name__ = true;
coopy.TableModifier.prototype = {
	removeColumn: function(at) {
		var fate = [];
		var _g1 = 0, _g = this.t.get_width();
		while(_g1 < _g) {
			var i = _g1++;
			if(i < at) fate.push(i); else if(i > at) fate.push(i - 1); else fate.push(-1);
		}
		return this.t.insertOrDeleteColumns(fate,this.t.get_width() - 1);
	}
	,__class__: coopy.TableModifier
}
coopy.TableText = function(rows) {
	this.rows = rows;
	this.view = rows.getCellView();
};
$hxExpose(coopy.TableText, "coopy.TableText");
coopy.TableText.__name__ = true;
coopy.TableText.prototype = {
	getCellText: function(x,y) {
		return this.view.toString(this.rows.getCell(x,y));
	}
	,__class__: coopy.TableText
}
coopy.TableView = function() {
};
$hxExpose(coopy.TableView, "coopy.TableView");
coopy.TableView.__name__ = true;
coopy.TableView.__interfaces__ = [coopy.View];
coopy.TableView.prototype = {
	toDatum: function(str) {
		return new coopy.SimpleCell(str);
	}
	,equals: function(d1,d2) {
		console.log("TableView.equals called");
		return false;
	}
	,hasStructure: function(d) {
		return true;
	}
	,getTable: function(d) {
		var table = d;
		return table;
	}
	,getBag: function(d) {
		return null;
	}
	,toString: function(d) {
		return "" + Std.string(d);
	}
	,__class__: coopy.TableView
}
coopy.Unit = function(l,r,p) {
	if(p == null) p = -2;
	if(r == null) r = -2;
	if(l == null) l = -2;
	this.l = l;
	this.r = r;
	this.p = p;
};
coopy.Unit.__name__ = true;
coopy.Unit.describe = function(i) {
	return i >= 0?"" + i:"-";
}
coopy.Unit.prototype = {
	fromString: function(txt) {
		txt += "]";
		var at = 0;
		var _g1 = 0, _g = txt.length;
		while(_g1 < _g) {
			var i = _g1++;
			var ch = HxOverrides.cca(txt,i);
			if(ch >= 48 && ch <= 57) {
				at *= 10;
				at += ch - 48;
			} else if(ch == 45) at = -1; else if(ch == 124) {
				this.p = at;
				at = 0;
			} else if(ch == 58) {
				this.l = at;
				at = 0;
			} else if(ch == 93) {
				this.r = at;
				return true;
			}
		}
		return false;
	}
	,toString: function() {
		if(this.p >= -1) return coopy.Unit.describe(this.p) + "|" + coopy.Unit.describe(this.l) + ":" + coopy.Unit.describe(this.r);
		return coopy.Unit.describe(this.l) + ":" + coopy.Unit.describe(this.r);
	}
	,lp: function() {
		return this.p == -2?this.l:this.p;
	}
	,__class__: coopy.Unit
}
coopy.ViewedDatum = function(datum,view) {
	this.datum = datum;
	this.view = view;
};
$hxExpose(coopy.ViewedDatum, "coopy.ViewedDatum");
coopy.ViewedDatum.__name__ = true;
coopy.ViewedDatum.getSimpleView = function(datum) {
	return new coopy.ViewedDatum(datum,new coopy.SimpleView());
}
coopy.ViewedDatum.prototype = {
	hasStructure: function() {
		return this.view.hasStructure(this.datum);
	}
	,getTable: function() {
		return this.view.getTable(this.datum);
	}
	,getBag: function() {
		return this.view.getBag(this.datum);
	}
	,toString: function() {
		return this.view.toString(this.datum);
	}
	,__class__: coopy.ViewedDatum
}
coopy.Viterbi = function() {
	this.K = this.T = 0;
	this.reset();
	this.cost = new coopy.SparseSheet();
	this.src = new coopy.SparseSheet();
	this.path = new coopy.SparseSheet();
};
$hxExpose(coopy.Viterbi, "coopy.Viterbi");
coopy.Viterbi.__name__ = true;
coopy.Viterbi.prototype = {
	getCost: function() {
		this.calculatePath();
		return this.best_cost;
	}
	,get: function(i) {
		this.calculatePath();
		return this.path.get(0,i);
	}
	,length: function() {
		if(this.index > 0) this.calculatePath();
		return this.index;
	}
	,toString: function() {
		this.calculatePath();
		var txt = "";
		var _g1 = 0, _g = this.index;
		while(_g1 < _g) {
			var i = _g1++;
			if(this.path.get(0,i) == -1) txt += "*"; else txt += this.path.get(0,i);
			if(this.K >= 10) txt += " ";
		}
		txt += " costs " + this.getCost();
		return txt;
	}
	,calculatePath: function() {
		if(this.path_valid) return;
		this.endTransitions();
		var best = 0;
		var bestj = -1;
		if(this.index <= 0) {
			this.path_valid = true;
			return;
		}
		var _g1 = 0, _g = this.K;
		while(_g1 < _g) {
			var j = _g1++;
			if((this.cost.get(j,this.index - 1) < best || bestj == -1) && this.src.get(j,this.index - 1) != -1) {
				best = this.cost.get(j,this.index - 1);
				bestj = j;
			}
		}
		this.best_cost = best;
		var _g1 = 0, _g = this.index;
		while(_g1 < _g) {
			var j = _g1++;
			var i = this.index - 1 - j;
			this.path.set(0,i,bestj);
			if(!(bestj != -1 && (bestj >= 0 && bestj < this.K))) console.log("Problem in Viterbi");
			bestj = this.src.get(bestj,i);
		}
		this.path_valid = true;
	}
	,beginTransitions: function() {
		this.path_valid = false;
		this.assertMode(1);
	}
	,endTransitions: function() {
		this.path_valid = false;
		this.assertMode(0);
	}
	,addTransition: function(s0,s1,c) {
		var resize = false;
		if(s0 >= this.K) {
			this.K = s0 + 1;
			resize = true;
		}
		if(s1 >= this.K) {
			this.K = s1 + 1;
			resize = true;
		}
		if(resize) {
			this.cost.nonDestructiveResize(this.K,this.T,0);
			this.src.nonDestructiveResize(this.K,this.T,-1);
			this.path.nonDestructiveResize(1,this.T,-1);
		}
		this.path_valid = false;
		this.assertMode(1);
		if(this.index >= this.T) {
			this.T = this.index + 1;
			this.cost.nonDestructiveResize(this.K,this.T,0);
			this.src.nonDestructiveResize(this.K,this.T,-1);
			this.path.nonDestructiveResize(1,this.T,-1);
		}
		var sourced = false;
		if(this.index > 0) {
			c += this.cost.get(s0,this.index - 1);
			sourced = this.src.get(s0,this.index - 1) != -1;
		} else sourced = true;
		if(sourced) {
			if(c < this.cost.get(s1,this.index) || this.src.get(s1,this.index) == -1) {
				this.cost.set(s1,this.index,c);
				this.src.set(s1,this.index,s0);
			}
		}
	}
	,assertMode: function(next) {
		if(next == 0 && this.mode == 1) this.index++;
		this.mode = next;
	}
	,setSize: function(states,sequence_length) {
		this.K = states;
		this.T = sequence_length;
		this.cost.resize(this.K,this.T,0);
		this.src.resize(this.K,this.T,-1);
		this.path.resize(1,this.T,-1);
	}
	,reset: function() {
		this.index = 0;
		this.mode = 0;
		this.path_valid = false;
		this.best_cost = 0;
	}
	,__class__: coopy.Viterbi
}
coopy.Workspace = function() {
};
coopy.Workspace.__name__ = true;
coopy.Workspace.prototype = {
	__class__: coopy.Workspace
}
var haxe = {}
haxe.Json = function() {
};
haxe.Json.__name__ = true;
haxe.Json.parse = function(text) {
	return new haxe.Json().doParse(text);
}
haxe.Json.stringify = function(value,replacer) {
	return new haxe.Json().toString(value,replacer);
}
haxe.Json.prototype = {
	parseNumber: function(c) {
		var start = this.pos - 1;
		var minus = c == 45, digit = !minus, zero = c == 48;
		var point = false, e = false, pm = false, end = false;
		while(true) {
			c = this.str.charCodeAt(this.pos++);
			switch(c) {
			case 48:
				if(zero && !point) this.invalidNumber(start);
				if(minus) {
					minus = false;
					zero = true;
				}
				digit = true;
				break;
			case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:
				if(zero && !point) this.invalidNumber(start);
				if(minus) minus = false;
				digit = true;
				zero = false;
				break;
			case 46:
				if(minus || point) this.invalidNumber(start);
				digit = false;
				point = true;
				break;
			case 101:case 69:
				if(minus || zero || e) this.invalidNumber(start);
				digit = false;
				e = true;
				break;
			case 43:case 45:
				if(!e || pm) this.invalidNumber(start);
				digit = false;
				pm = true;
				break;
			default:
				if(!digit) this.invalidNumber(start);
				this.pos--;
				end = true;
			}
			if(end) break;
		}
		var f = Std.parseFloat(HxOverrides.substr(this.str,start,this.pos - start));
		var i = f | 0;
		return i == f?i:f;
	}
	,invalidNumber: function(start) {
		throw "Invalid number at position " + start + ": " + HxOverrides.substr(this.str,start,this.pos - start);
	}
	,parseString: function() {
		var start = this.pos;
		var buf = new StringBuf();
		while(true) {
			var c = this.str.charCodeAt(this.pos++);
			if(c == 34) break;
			if(c == 92) {
				buf.addSub(this.str,start,this.pos - start - 1);
				c = this.str.charCodeAt(this.pos++);
				switch(c) {
				case 114:
					buf.b += "\r";
					break;
				case 110:
					buf.b += "\n";
					break;
				case 116:
					buf.b += "\t";
					break;
				case 98:
					buf.b += "";
					break;
				case 102:
					buf.b += "";
					break;
				case 47:case 92:case 34:
					buf.b += String.fromCharCode(c);
					break;
				case 117:
					var uc = Std.parseInt("0x" + HxOverrides.substr(this.str,this.pos,4));
					this.pos += 4;
					buf.b += String.fromCharCode(uc);
					break;
				default:
					throw "Invalid escape sequence \\" + String.fromCharCode(c) + " at position " + (this.pos - 1);
				}
				start = this.pos;
			} else if(c != c) throw "Unclosed string";
		}
		buf.addSub(this.str,start,this.pos - start - 1);
		return buf.b;
	}
	,parseRec: function() {
		while(true) {
			var c = this.str.charCodeAt(this.pos++);
			switch(c) {
			case 32:case 13:case 10:case 9:
				break;
			case 123:
				var obj = { }, field = null, comma = null;
				while(true) {
					var c1 = this.str.charCodeAt(this.pos++);
					switch(c1) {
					case 32:case 13:case 10:case 9:
						break;
					case 125:
						if(field != null || comma == false) this.invalidChar();
						return obj;
					case 58:
						if(field == null) this.invalidChar();
						obj[field] = this.parseRec();
						field = null;
						comma = true;
						break;
					case 44:
						if(comma) comma = false; else this.invalidChar();
						break;
					case 34:
						if(comma) this.invalidChar();
						field = this.parseString();
						break;
					default:
						this.invalidChar();
					}
				}
				break;
			case 91:
				var arr = [], comma = null;
				while(true) {
					var c1 = this.str.charCodeAt(this.pos++);
					switch(c1) {
					case 32:case 13:case 10:case 9:
						break;
					case 93:
						if(comma == false) this.invalidChar();
						return arr;
					case 44:
						if(comma) comma = false; else this.invalidChar();
						break;
					default:
						if(comma) this.invalidChar();
						this.pos--;
						arr.push(this.parseRec());
						comma = true;
					}
				}
				break;
			case 116:
				var save = this.pos;
				if(this.str.charCodeAt(this.pos++) != 114 || this.str.charCodeAt(this.pos++) != 117 || this.str.charCodeAt(this.pos++) != 101) {
					this.pos = save;
					this.invalidChar();
				}
				return true;
			case 102:
				var save = this.pos;
				if(this.str.charCodeAt(this.pos++) != 97 || this.str.charCodeAt(this.pos++) != 108 || this.str.charCodeAt(this.pos++) != 115 || this.str.charCodeAt(this.pos++) != 101) {
					this.pos = save;
					this.invalidChar();
				}
				return false;
			case 110:
				var save = this.pos;
				if(this.str.charCodeAt(this.pos++) != 117 || this.str.charCodeAt(this.pos++) != 108 || this.str.charCodeAt(this.pos++) != 108) {
					this.pos = save;
					this.invalidChar();
				}
				return null;
			case 34:
				return this.parseString();
			case 48:case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:case 45:
				return this.parseNumber(c);
			default:
				this.invalidChar();
			}
		}
	}
	,invalidChar: function() {
		this.pos--;
		throw "Invalid char " + this.str.charCodeAt(this.pos) + " at position " + this.pos;
	}
	,doParse: function(str) {
		this.str = str;
		this.pos = 0;
		return this.parseRec();
	}
	,quote: function(s) {
		this.buf.b += "\"";
		var i = 0;
		while(true) {
			var c = s.charCodeAt(i++);
			if(c != c) break;
			switch(c) {
			case 34:
				this.buf.b += "\\\"";
				break;
			case 92:
				this.buf.b += "\\\\";
				break;
			case 10:
				this.buf.b += "\\n";
				break;
			case 13:
				this.buf.b += "\\r";
				break;
			case 9:
				this.buf.b += "\\t";
				break;
			case 8:
				this.buf.b += "\\b";
				break;
			case 12:
				this.buf.b += "\\f";
				break;
			default:
				this.buf.b += String.fromCharCode(c);
			}
		}
		this.buf.b += "\"";
	}
	,toStringRec: function(k,v) {
		if(this.replacer != null) v = this.replacer(k,v);
		var _g = Type["typeof"](v);
		var $e = (_g);
		switch( $e[1] ) {
		case 8:
			this.buf.b += "\"???\"";
			break;
		case 4:
			this.objString(v);
			break;
		case 1:
			var v1 = v;
			this.buf.b += Std.string(v1);
			break;
		case 2:
			this.buf.b += Std.string(Math.isFinite(v)?v:"null");
			break;
		case 5:
			this.buf.b += "\"<fun>\"";
			break;
		case 6:
			var _g_eTClass_0 = $e[2];
			if(_g_eTClass_0 == String) this.quote(v); else if(_g_eTClass_0 == Array) {
				var v1 = v;
				this.buf.b += "[";
				var len = v1.length;
				if(len > 0) {
					this.toStringRec(0,v1[0]);
					var i = 1;
					while(i < len) {
						this.buf.b += ",";
						this.toStringRec(i,v1[i++]);
					}
				}
				this.buf.b += "]";
			} else if(_g_eTClass_0 == haxe.ds.StringMap) {
				var v1 = v;
				var o = { };
				var $it0 = v1.keys();
				while( $it0.hasNext() ) {
					var k1 = $it0.next();
					o[k1] = v1.get(k1);
				}
				this.objString(o);
			} else this.objString(v);
			break;
		case 7:
			var i = Type.enumIndex(v);
			var v1 = i;
			this.buf.b += Std.string(v1);
			break;
		case 3:
			var v1 = v;
			this.buf.b += Std.string(v1);
			break;
		case 0:
			this.buf.b += "null";
			break;
		}
	}
	,objString: function(v) {
		this.fieldsString(v,Reflect.fields(v));
	}
	,fieldsString: function(v,fields) {
		var first = true;
		this.buf.b += "{";
		var _g = 0;
		while(_g < fields.length) {
			var f = fields[_g];
			++_g;
			var value = Reflect.field(v,f);
			if(Reflect.isFunction(value)) continue;
			if(first) first = false; else this.buf.b += ",";
			this.quote(f);
			this.buf.b += ":";
			this.toStringRec(f,value);
		}
		this.buf.b += "}";
	}
	,toString: function(v,replacer) {
		this.buf = new StringBuf();
		this.replacer = replacer;
		this.toStringRec("",v);
		return this.buf.b;
	}
	,__class__: haxe.Json
}
haxe.ds = {}
haxe.ds.IntMap = function() {
	this.h = { };
};
haxe.ds.IntMap.__name__ = true;
haxe.ds.IntMap.__interfaces__ = [IMap];
haxe.ds.IntMap.prototype = {
	toString: function() {
		var s = new StringBuf();
		s.b += "{";
		var it = this.keys();
		while( it.hasNext() ) {
			var i = it.next();
			s.b += Std.string(i);
			s.b += " => ";
			s.b += Std.string(Std.string(this.get(i)));
			if(it.hasNext()) s.b += ", ";
		}
		s.b += "}";
		return s.b;
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key | 0);
		}
		return HxOverrides.iter(a);
	}
	,remove: function(key) {
		if(!this.h.hasOwnProperty(key)) return false;
		delete(this.h[key]);
		return true;
	}
	,exists: function(key) {
		return this.h.hasOwnProperty(key);
	}
	,get: function(key) {
		return this.h[key];
	}
	,set: function(key,value) {
		this.h[key] = value;
	}
	,__class__: haxe.ds.IntMap
}
haxe.ds.StringMap = function() {
	this.h = { };
};
haxe.ds.StringMap.__name__ = true;
haxe.ds.StringMap.__interfaces__ = [IMap];
haxe.ds.StringMap.prototype = {
	iterator: function() {
		return { ref : this.h, it : this.keys(), hasNext : function() {
			return this.it.hasNext();
		}, next : function() {
			var i = this.it.next();
			return this.ref["$" + i];
		}};
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key.substr(1));
		}
		return HxOverrides.iter(a);
	}
	,exists: function(key) {
		return this.h.hasOwnProperty("$" + key);
	}
	,get: function(key) {
		return this.h["$" + key];
	}
	,set: function(key,value) {
		this.h["$" + key] = value;
	}
	,__class__: haxe.ds.StringMap
}
var js = {}
js.Boot = function() { }
js.Boot.__name__ = true;
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2, _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i;
			var str = "[";
			s += "\t";
			var _g = 0;
			while(_g < l) {
				var i1 = _g++;
				str += (i1 > 0?",":"") + js.Boot.__string_rec(o[i1],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) { ;
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
}
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0, _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
}
js.Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) {
					if(cl == Array) return o.__enum__ == null;
					return true;
				}
				if(js.Boot.__interfLoop(o.__class__,cl)) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true; else null;
		if(cl == Enum && o.__ename__ != null) return true; else null;
		return o.__enum__ == cl;
	}
}
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; };
var $_;
function $bind(o,m) { var f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; return f; };
Math.__name__ = ["Math"];
Math.NaN = Number.NaN;
Math.NEGATIVE_INFINITY = Number.NEGATIVE_INFINITY;
Math.POSITIVE_INFINITY = Number.POSITIVE_INFINITY;
Math.isFinite = function(i) {
	return isFinite(i);
};
Math.isNaN = function(i) {
	return isNaN(i);
};
String.prototype.__class__ = String;
String.__name__ = true;
Array.prototype.__class__ = Array;
Array.__name__ = true;
var Int = { __name__ : ["Int"]};
var Dynamic = { __name__ : ["Dynamic"]};
var Float = Number;
Float.__name__ = ["Float"];
var Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = { __name__ : ["Class"]};
var Enum = { };
if(typeof(JSON) != "undefined") haxe.Json = JSON;
coopy.Coopy.main();
function $hxExpose(src, path) {
	var o = typeof exports != "undefined" ? exports : window;
	var parts = path.split(".");
	for(var ii = 0; ii < parts.length-1; ++ii) {
		var p = parts[ii];
		if(typeof o[p] == "undefined") o[p] = {};
		o = o[p];
	}
	o[parts[parts.length-1]] = src;
}
})();

//@ sourceMappingURL=coopy.js.map

if (typeof exports != "undefined") {
    // avoid having excess nesting (coopy.coopy) when using node
    for (f in exports.coopy) { 
	if (exports.coopy.hasOwnProperty(f)) {
	    exports[f] = exports.coopy[f]; 
	}
    } 
    // promote methods of coopy.Coopy
    for (f in exports.Coopy) { 
	if (exports.Coopy.hasOwnProperty(f)) {
	    exports[f] = exports.Coopy[f]; 
	}
    } 
} else {
    // promote methods of coopy.Coopy
    for (f in coopy.Coopy) { 
	if (coopy.Coopy.hasOwnProperty(f)) {
	    coopy[f] = coopy.Coopy[f]; 
	}
    } 
}
(function() {

var coopy = null;
if (typeof exports != "undefined") {
    if (typeof exports.Coopy != "undefined") {
	coopy = exports;
    }
}
if (coopy == null) {
    coopy = window.coopy;
}

var CoopyTableView = function(data) {
    // variant constructor (cols, rows)
    if (arguments.length==2) {
	var lst = [];
	for (var i=0; i<arguments[1]; i++) {
	    var row = [];
	    for (var j=0; j<arguments[0]; j++) {
		row.push(null);
	    }
	    lst.push(row);
	}
	data = lst;
    }
    this.data = data;
    this.height = data.length;
    this.width = 0;
    if (this.height>0) {
	this.width = data[0].length;
    }
}

CoopyTableView.prototype.get_width = function() {
    return this.width;
}

CoopyTableView.prototype.get_height = function() {
    return this.height;
}

CoopyTableView.prototype.getCell = function(x,y) {
    return this.data[y][x];
}

CoopyTableView.prototype.setCell = function(x,y,c) {
    this.data[y][x] = c;
}

CoopyTableView.prototype.toString = function() {
    return coopy.SimpleTable.tableToString(this);
}

CoopyTableView.prototype.getCellView = function() {
    return new coopy.SimpleView();
}

CoopyTableView.prototype.isResizable = function() {
    return true;
}

CoopyTableView.prototype.resize = function(w,h) {
    this.width = w;
    this.height = h;
    for (var i=0; i<this.data.length; i++) {
	var row = this.data[i];
	if (row==null) {
	    row = this.data[i] = [];
	}
	while (row.length<this.width) {
	    row.push(null);
	}
    }
    if (this.data.length<this.height) {
	while (this.data.length<this.height) {
	    var row = [];
	    for (var i=0; i<this.width; i++) {
		row.push(null);
	    }
	    this.data.push(row);
	}
    }
    return true;
}

CoopyTableView.prototype.clear = function() {
    for (var i=0; i<this.data.length; i++) {
	var row = this.data[i];
	for (var j=0; j<row.length; j++) {
	    row[j] = null;
	}
    }
}

CoopyTableView.prototype.trim = function() {
    var changed = this.trimRows();
    changed = changed || this.trimColumns();
    return changed;
}

CoopyTableView.prototype.trimRows = function() {
    var changed = false;
    while (true) {
	if (this.height==0) return changed;
	var row = this.data[this.height-1];
	for (var i=0; i<this.width; i++) {
	    var c = row[i];
	    if (c!=null && c!="") return changed;
	}
	this.height--;
    }
}

CoopyTableView.prototype.trimColumns = function() {
    var top_content = 0;
    for (var i=0; i<this.height; i++) {
	if (top_content>=this.width) break;
	var row = this.data[i];
	for (var j=0; j<this.width; j++) {
	    var c = row[j];
	    if (c!=null && c!="") {
		if (j>top_content) {
		    top_content = j;
		}
	    }
	}
    }
    if (this.height==0 || top_content+1==this.width) return false;
    this.width = top_content+1;
    return true;
}

CoopyTableView.prototype.getData = function() {
    return this.data;
}

CoopyTableView.prototype.clone = function() {
    var ndata = [];
    for (var i=0; i<this.get_height(); i++) {
	ndata[i] = this.data[i].slice();
    }
    return new CoopyTableView(ndata);
}

CoopyTableView.prototype.insertOrDeleteRows = function(fate, hfate) {
    var ndata = [];
    for (var i=0; i<fate.length; i++) {
        var j = fate[i];
        if (j!=-1) {
	    ndata[j] = this.data[i];
        }
    }
    // let's preserve data
    //this.data = ndata;
    this.data.length = 0;
    for (var i=0; i<ndata.length; i++) {
	this.data[i] = ndata[i];
    }
    this.resize(this.width,hfate);
    return true;
}

CoopyTableView.prototype.insertOrDeleteColumns = function(fate, wfate) {
    if (wfate==this.width && wfate==fate.length) {
	var eq = true;
	for (var i=0; i<wfate; i++) {
	    if (fate[i]!=i) {
		eq = false;
		break;
	    }
	}
	if (eq) return true;
    }
    for (var i=0; i<this.height; i++) {
	var row = this.data[i];
	var nrow = [];
	for (var j=0; j<this.width; j++) {
	    if (fate[j]==-1) continue;
	    nrow[fate[j]] = row[j];
	}
	while (nrow.length<wfate) {
	    nrow.push(null);
	}
	this.data[i] = nrow;
    }
    this.width = wfate;
    return true;
}

CoopyTableView.prototype.isSimilar = function(alt) {
    if (alt.width!=this.width) return false;
    if (alt.height!=this.height) return false;
    for (var c=0; c<this.width; c++) {
	for (var r=0; r<this.height; r++) {
	    var v1 = "" + this.getCell(c,r);
	    var v2 = "" + alt.getCell(c,r); 
	    if (v1!=v2) {
		console.log("MISMATCH "+ v1 + " " + v2);
		return false;
	    }
	}
    }
    return true;
}

if (typeof exports != "undefined") {
    exports.CoopyTableView = CoopyTableView;
} else {
    if (typeof window["coopy"] == "undefined") window["coopy"] = {};
    window.coopy.CoopyTableView = CoopyTableView;
}

})();
